---
module_id: dv-011-retain-raw-counts-behind-normalized-heatmaps
department: data-visualization
course: "Conserver les effectifs derrière une carte thermique normalisée"
level: intermediate
prerequisites: ["dv-002-denominators-and-test-populations", "dv-008-streeling-evidence-stage-map"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Conserver les effectifs derrière une carte thermique normalisée

> Brouillon à soumettre à une relecture humaine. Les cas fixes ci-dessous sont des modèles mathématiques rédigés après lecture des sources ; ce ne sont pas de nouvelles mesures du projet. Les avis techniques, artisanaux, linguistiques et pédagogiques restent en attente. Aucun moteur de scène, échantillon physique, GPU, exécuteur de politique ni essai avec un apprenant n’a été utilisé pour cette leçon.

## Question du projet

Un tableau Learn normalise chaque ligne d’une carte thermique des états de preuve. Deux lignes semblent également réussies, mais l’une couvre un groupe minuscule et l’autre un groupe plus grand. Que peut-on encore reconstruire à partir des couleurs ? L’ancien rejeu du schéma consultatif est un véritable document de contrôle limité, pas une observation des cellules inventées ici. La question du tableau permet d’étudier une transformation d’affichage qui perd de l’information.

[Prérequis: dv-002-denominators-and-test-populations](../../data-visualization/en/dv-002-denominators-and-test-populations.md); [Prérequis: dv-008-streeling-evidence-stage-map](../../data-visualization/en/dv-008-streeling-evidence-stage-map.md)

## Lire le périmètre avant de calculer

Lisez le prérequis et le document du projet avant de calculer. Distinguez les affirmations tirées du code inspecté, les résultats consignés antérieurement et les conséquences des seules hypothèses ci-dessous. Un commentaire de code, un corrigé préparé et une observation exécutée n’ont pas la même valeur probante. Conservez la date d’origine ainsi que tout contrôle échoué ou non concluant dans votre résumé d’un ancien document. La référence manuelle est un petit calcul sur papier accompagné d’un tableau des emplacements dans les sources ; un agent peut aider à trouver une définition, mais son résumé doit être confronté à celle-ci. Ce cas fini ne nécessite aucun nouveau langage ni automatisme.

Divisez chaque cellule par le total de sa ligne uniquement si celui-ci est positif. Gardez la matrice initiale, les libellés, la population et la règle de normalisation à côté de l’affichage. Multiplier toute une ligne positive par un facteur conserve ses valeurs normalisées : la couleur n’identifie donc pas l’effectif initial. Un total conservé permet la reconstruction avant arrondi ; des pourcentages arrondis peuvent laisser plusieurs possibilités entières. Une ligne vide n’a pas de proportion empirique et doit rester manquante plutôt qu’apparaître comme un échec mesuré. Cela prolonge les taux pondérés du prérequis par une transformation non injective et une condition explicite de reconstruction.

## Cas fixe et hypothèses

```text
columns=["pass","fail"]
A=[1,1]; B=[20,20]; Empty=[0,0]
row_normalized_A=[0.5,0.5]; row_normalized_B=[0.5,0.5]
raw_column_totals=[21,21]; raw_total=42
control_C=[2,8]; normalized_C=[0.2,0.8]
Empty_normalized=null
```

## Exercices corrigés

### Exercice 1

Normalisez les deux lignes équilibrées non vides.

> **Réponse:** Les deux deviennent `[0.5,0.5]`, avec des totaux de `2` et `40`. Des couleurs identiques ne prouvent pas des volumes de preuve identiques.

### Exercice 2

Les seules lignes normalisées permettent-elles de retrouver les totaux ?

> **Réponse:** Non. `[1,1]` et `[20,20]` sont deux antécédents distincts. Gardez les effectifs ou les totaux exacts avec les proportions non arrondies.

### Exercice 3

Agrégez les lignes équilibrées initiales.

> **Réponse:** Les totaux sont `[21,21]` pour `42` enregistrements. La proportion globale de réussite est `0.5`, avec son dénominateur conservé.

### Exercice 4

Normalisez le contrôle déséquilibré et la ligne vide.

> **Réponse:** Le contrôle donne `[0.2,0.8]` ; la ligne vide vaut `null`. La remplir avec `[0,0]` ferait passer une proportion indéfinie pour des valeurs mesurées.

### Exercice 5

Une cellule normalisée d’état établit-elle une relecture autorisée ?

> **Réponse:** Non. L’effectif exige encore le document sous-jacent et son lien à la source exacte. La normalisation change la présentation, pas l’autorité ni la validité du reçu.

## Tâche assistée par les sources

Lisez le rejeu conservé et repérez le cas accepté malgré des preuves vides. Préparez manuellement un tableau d’effectifs pour une carte Learn proposée ; marquez les cellules comme hypothétiques. Demandez une légende à une aide et rejetez-la si elle déduit effectifs égaux ou approbation humaine de couleurs identiques.

Réalisez la tâche en masquant les corrigés. Gardez vos réponses initiales, les étapes de calcul, les emplacements dans les sources, les incertitudes et toutes les aides reçues, y compris un indice, un terme traduit ou une suggestion d’agent. Comparez ensuite avec les réponses préparées et consignez les corrections sans effacer votre premier essai. Rédigez une courte note de décision présentant l’affirmation, ses hypothèses, le calcul, le contrôle négatif et l’observation susceptible de la réfuter. Un résultat juste dépourvu d’unité ou d’identité de source ne suffit pas à démontrer le transfert. Le dossier comporte cinq critères préparés pour l’apprenant ; leur décision reste null tant qu’il n’existe pas d’essai réel et de relecture autorisée. La réussite de ces calculs établirait seulement une compétence sur le cas déclaré. Elle ne prouverait ni adaptateur opérationnel, ni procédé matériel réussi, ni moteur de rendu plus rapide, ni progrès d’apprentissage dans le projet. Comparez votre note assistée à la référence manuelle : si l’aide masque une hypothèse ou supprime un refus, corrigez la note avant de proposer un changement de méthode.

## Sources et journal de validation

- [Document du projet](../../../../code/streeling/evidence/representation-release-2026-10-22/phi002-schema-replay.json)
- [Source primaire](https://github.com/spareilleux/learn/blob/8f13637ae4596b614c2ba493b596b6a08e1cf43a/scripts/streeling-lib.mjs)
- [Dossier de preuves fixes](../../../../code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
