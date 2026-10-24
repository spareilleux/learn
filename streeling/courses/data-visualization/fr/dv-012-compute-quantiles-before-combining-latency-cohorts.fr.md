---
module_id: dv-012-compute-quantiles-before-combining-latency-cohorts
department: data-visualization
course: "Calculer les quantiles avant de réunir des cohortes de latence"
level: intermediate
prerequisites: ["dv-003-instrument-cohorts-and-units", "dv-005-baselines-alerts-and-targets"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Calculer les quantiles avant de réunir des cohortes de latence

> Brouillon à soumettre à une relecture humaine. Les cas fixes ci-dessous sont des modèles mathématiques rédigés après lecture des sources ; ce ne sont pas de nouvelles mesures du projet. Les avis techniques, artisanaux, linguistiques et pédagogiques restent en attente. Aucun moteur de scène, échantillon physique, GPU, exécuteur de politique ni essai avec un apprenant n’a été utilisé pour cette leçon.

## Question du projet

Un rapport de rendu GA et un worker de publication fournissent chacun une durée médiane. Un tableau peut-il moyenner ces médianes pour obtenir celle de toutes les requêtes ? Le dossier historique BRUTAL précise déjà que les bornes de chronométrage différaient entre rapports et que la coexistence restait non concluante. Cette limite est conservée ; seuls de nouveaux échantillons construits servent à étudier les quantiles réunis.

[Prérequis: dv-003-instrument-cohorts-and-units](../../data-visualization/en/dv-003-instrument-cohorts-and-units.md); [Prérequis: dv-005-baselines-alerts-and-targets](../../data-visualization/en/dv-005-baselines-alerts-and-targets.md)

## Lire le périmètre avant de calculer

Lisez le prérequis et le document du projet avant de calculer. Distinguez les affirmations tirées du code inspecté, les résultats consignés antérieurement et les conséquences des seules hypothèses ci-dessous. Un commentaire de code, un corrigé préparé et une observation exécutée n’ont pas la même valeur probante. Conservez la date d’origine ainsi que tout contrôle échoué ou non concluant dans votre résumé d’un ancien document. La référence manuelle est un petit calcul sur papier accompagné d’un tableau des emplacements dans les sources ; un agent peut aider à trouver une définition, mais son résumé doit être confronté à celle-ci. Ce cas fini ne nécessite aucun nouveau langage ni automatisme.

NIST présente plusieurs conventions de percentile ; choisissez donc la règle avant de comparer. Ici, utilisez le rang supérieur : triez les observations finies et prenez l’élément au plafond de la probabilité multipliée par l’effectif, avec des rangs commençant à un. C’est une convention pédagogique explicite, pas une description de toutes les métriques du projet. Ne réunissez les observations que si unités, bornes de mesure et populations visées sont comparables. La moyenne des quantiles de groupes n’est pas nécessairement un quantile global. Les valeurs identiques restent des observations distinctes dans cette liste, sans prouver indépendance ni représentativité.

## Cas fixe et hypothèses

```text
A_ms=[1,2,100]; B_ms=[3,4,5,6,7]
Q(p,x)=sorted(x)[ceil(p*len(x))-1]
Q(0.5,A)=2; Q(0.5,B)=5; mean_medians=3.5
pooled_ms=[1,2,3,4,5,6,7,100]; Q(0.5,pooled)=4
Q(0.9,A)=100; Q(0.9,B)=7; Q(0.9,pooled)=100
control_A_ms=[2,2]; control_B_ms=[2,2,2]; Q(0.5,control_pooled)=2
```

## Exercices corrigés

### Exercice 1

Trouvez les deux médianes selon la règle déclarée.

> **Réponse:** Elles valent `2 ms` et `5 ms`. Leur moyenne simple vaut `3.5 ms` : c’est un autre résumé, pas une médiane globale.

### Exercice 2

Calculez la médiane réunie.

> **Réponse:** Il y a `8` observations triées. Le rang `4` donne `4 ms`. La règle déclarée importe pour cet effectif pair.

### Exercice 3

Trouvez le quantile supérieur global du modèle.

> **Réponse:** À `0.9`, le rang `8` donne `100 ms`. La moyenne des valeurs de groupes serait `53.5 ms`, qui n’est pas ce quantile global.

### Exercice 4

Que montre le contrôle à valeur constante ?

> **Réponse:** Toutes les médianes valent `2 ms`. L’accord est possible : on réfute une règle générale, pas toute possibilité d’égalité.

### Exercice 5

Peut-on réunir les anciens temps de rendu aux bornes différentes après conversion d’unité ?

> **Réponse:** Non. Les unités ne réconcilient pas des intervalles mesurés différents. Conservez les contrôles échoués et non concluants ; demandez bornes communes et échantillons bruts.

## Tâche assistée par les sources

Lisez les champs de bornes temporelles de la comparaison historique. Dressez un tableau manuel séparant échantillons construits compatibles et anciennes mesures incomparables. Faites proposer une légende par une aide, puis réfutez-la si elle substitue des médianes moyennées ou fusionne des bornes différentes.

Réalisez la tâche en masquant les corrigés. Gardez vos réponses initiales, les étapes de calcul, les emplacements dans les sources, les incertitudes et toutes les aides reçues, y compris un indice, un terme traduit ou une suggestion d’agent. Comparez ensuite avec les réponses préparées et consignez les corrections sans effacer votre premier essai. Rédigez une courte note de décision présentant l’affirmation, ses hypothèses, le calcul, le contrôle négatif et l’observation susceptible de la réfuter. Un résultat juste dépourvu d’unité ou d’identité de source ne suffit pas à démontrer le transfert. Le dossier comporte cinq critères préparés pour l’apprenant ; leur décision reste null tant qu’il n’existe pas d’essai réel et de relecture autorisée. La réussite de ces calculs établirait seulement une compétence sur le cas déclaré. Elle ne prouverait ni adaptateur opérationnel, ni procédé matériel réussi, ni moteur de rendu plus rapide, ni progrès d’apprentissage dans le projet. Comparez votre note assistée à la référence manuelle : si l’aide masque une hypothèse ou supprime un refus, corrigez la note avant de proposer un changement de méthode.

## Sources et journal de validation

- [Document du projet](../../../../code/streeling/evidence/brutal-composition-2026-10-22/historical-comparison.json)
- [Source primaire](https://www.itl.nist.gov/div898/handbook/prc/section2/prc262.htm)
- [Dossier de preuves fixes](../../../../code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
