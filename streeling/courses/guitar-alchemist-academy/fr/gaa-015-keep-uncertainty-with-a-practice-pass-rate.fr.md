---
module_id: gaa-015-keep-uncertainty-with-a-practice-pass-rate
department: guitar-alchemist-academy
course: "Conserver l’incertitude avec un taux de réussite"
level: advanced
prerequisites: ["gaa-010-define-a-practice-pass-before-counting-success"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Conserver l’incertitude avec un taux de réussite

> Modèle construit et lecture de sources. Les avis techniques humains, linguistiques, musicaux et pédagogiques restent en attente. Aucun nouveau jeu, essai d’écoute, analyse exécutée, rendu du moteur ou usage en production n’est revendiqué.

Un même pourcentage peut reposer sur des quantités de preuves très différentes. Un bilan de pratique [GA](https://github.com/GuitarAlchemist/ga) doit conserver le dénominateur et une règle d’incertitude explicite avant d’annoncer un objectif établi. Nous calculons un intervalle de Wilson sur des réussites construites, sous hypothèse binomiale, sans relevé réel d’apprenant.

## Lire les éléments conservés

Le manuel principal donne les bornes de Wilson et les distingue d’un autre intervalle ajusté. Comparez sa formule aux règles de réussite du relevé conservé. Un intervalle statistique ne corrige ni une définition ambiguë de réussite ni la confusion entre réponses assistées et autonomes.

[Prérequis](../../guitar-alchemist-academy/en/gaa-010-define-a-practice-pass-before-counting-success.md)

[Artefact du projet conservé](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/practice-items.json)

[Dossier des cas construits](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Lecture principale](https://www.itl.nist.gov/div898/handbook/prc/section2/prc241.htm)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "passes": 8,
    "attempts": 10,
    "z": 1.96,
    "required_lower_bound": 0.7
  },
  "formula": "p=k/n; d=1+z^2/n; center=(p+z^2/(2*n))/d; half=z*sqrt(p*(1-p)/n+z^2/(4*n^2))/d; lower=center-half; upper=center+half; established=lower>=required_lower_bound",
  "expected": {
    "rate": 0.8,
    "lower": 0.49015684672072346,
    "upper": 0.9433190520193067,
    "established": false
  },
  "negative_control": {
    "values": {
      "passes": 80,
      "attempts": 100,
      "z": 1.96,
      "required_lower_bound": 0.7
    },
    "expected": {
      "rate": 0.8,
      "lower": 0.7111690380734976,
      "upper": 0.8666340774409013,
      "established": true
    }
  }
}
```

## Adapter le modèle d’incertitude à la collecte des tentatives

Un taux exige une unité d’observation et un critère stable. Compter les notes comme tentatives indépendantes après avoir défini la réussite sur la phrase entière changerait le dénominateur et la grandeur visée. Mélanger tentatives assistées et autonomes change aussi le sens du taux, même avec une arithmétique correcte. Gardez résultats bruts et règle d’échantillonnage pour permettre de reconstruire les comptes.

L’intervalle choisi est fréquentiste et repose sur un modèle d’échantillonnages répétés. Il n’attribue pas à un paramètre fixe inconnu la probabilité indiquée de se trouver dans cet intervalle particulier. Manquer le seuil inférieur n’établit pas non plus une infériorité. La règle de décision est une convention prévue pour ce cours ; ses hypothèses doivent être examinées avant une utilisation réelle.

La pratique viole facilement l’hypothèse d’un taux commun : l’apprenant peut progresser, se fatiguer ou retenir les corrections pendant la suite. Multiplier les répétitions ne répare pas automatiquement ce décalage de modèle. Un rapport utile conserverait blocs chronologiques, assistance et identité des exercices, puis choisirait une analyse adaptée à la collecte. Le calcul manuel de Wilson sert de référence pour comprendre l’incertitude proposée ; un agent ne doit pas donner une autorité artificielle à l’intervalle en omettant ses conditions.

### Exercice 1

Calculez le taux principal. Pourquoi ne suffit-il pas à la décision déclarée ?

<details><summary>Réponse 1</summary>

Le taux figure ci-dessous, mais la règle compare la borne inférieure au seuil prévu. Un pourcentage seul ne contient pas cette information d’incertitude.

</details>

### Exercice 2

Calculez les bornes avec la constante donnée. Est-ce l’intervalle symétrique de Wald ?

<details><summary>Réponse 2</summary>

Utilisez le centre et la demi-largeur affichés. La méthode ajuste le dénominateur et le centre ; la remplacer par une erreur type autour du taux changerait le calcul.

</details>

### Exercice 3

Appliquez la règle de borne inférieure. Qu’est-ce qui n’est pas établi exactement ?

<details><summary>Réponse 3</summary>

La borne principale reste sous le seuil. C’est une décision selon cette règle, sans démontrer que le taux sous-jacent est inférieur au seuil.

</details>

### Exercice 4

Appliquez le témoin de même taux. Pourquoi la décision change-t-elle ?

<details><summary>Réponse 4</summary>

L’effectif supposé plus grand resserre l’intervalle et relève sa borne inférieure au-delà du seuil. Le calcul dépend de l’indépendance et du taux commun supposés.

</details>

### Exercice 5

Qu’est-ce qui invaliderait un tel intervalle comme preuve de maîtrise ?

<details><summary>Réponse 5</summary>

Un dénominateur inconnu, une grille modifiée, des prises dépendantes ou un apprentissage en cours fragilisent ce modèle. Des comptes construits ne prouvent jamais des tentatives réelles.

</details>

## Travail avec consultation des sources

Calculez les intervalles à la main, consignez la règle prévue et expliquez les hypothèses d’échantillonnage. Examinez les limites de l’assistance dans le relevé. Proposez un rapport gardant les comptes et la dépendance non résolue ; précisez quand abandonner l’interprétation binomiale.

Conservez d’abord votre raisonnement sans aide, avant de révéler les réponses. Examinez ensuite un passage précis avec sa révision, consignez chaque aide reçue et gardez séparément la réponse initiale et sa correction. Votre résultat manuel sert de référence pour toute calculatrice, proposition de DSL ou intervention d’agent. Une donnée manquante reste non résolue. Le dossier contient un critère préparé par exercice, sans décision d’apprenant. Une réponse correcte ne justifie que le cas déclaré ; l’acceptation exige une tentative réelle et sa revue. Formulez un critère de réfutation avant toute abstraction, puis indiquez les preuves humaines ou d’exécution nécessaires à la prochaine étape.
