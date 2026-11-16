---
title: Distinguer le décalage continu de l’énergie alternative
description: Distinguer le décalage continu de l’énergie alternative — Ingénierie audio
sidebar:
  label: AUD-016 · Distinguer le décalage continu de l’énergie alternative
  order: 16
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/audio-engineering/fr/aud-016-separate-dc-offset-from-ac-energy.fr.md
---

:::note[Streeling University]
**AUD-016** · Distinguer le décalage continu de l’énergie alternative · avancé · 60 minutes

Généré par le département *Ingénierie audio* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/audio-engineering/fr/aud-016-separate-dc-offset-from-ac-energy.fr.md) · [Mon journal](../../journal/)

Prérequis: [AUD-005](../../audio-engineering/aud-005-pcm-guards-and-format-boundaries/)
:::

> Modèle construit et lecture de sources. Les avis techniques humains, linguistiques, musicaux et pédagogiques restent en attente. Aucun nouveau jeu, essai d’écoute, analyse exécutée, rendu du moteur ou usage en production n’est revendiqué.

Un tampon de guitare peut respecter les limites de chaque échantillon tout en présentant un décalage continu. Un appariement du niveau efficace total peut alors attribuer des niveaux différents à des composantes alternatives identiques. Ce cours décompose un enregistrement fini avant de choisir un gain. Le calcul éclaire le script [GA](https://github.com/GuitarAlchemist/ga) conservé, qui élève les échantillons au carré sans retirer leur moyenne.

## Lire les éléments conservés

Lisez le contrôle des échantillons et le cumul du niveau efficace dans le script. Ils définissent son calcul à la révision indiquée, sans garantir une moyenne nulle pour tout tampon futur. La séquence ci-dessous est construite pour le cours ; aucun nouvel audio n’a été produit.

[Prérequis](../../audio-engineering/aud-005-pcm-guards-and-format-boundaries/)

[Artefact du projet conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/run.mjs)

[Dossier des cas construits](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-a.json)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "samples": [
      0,
      1,
      0,
      1
    ]
  },
  "formula": "mean=sum(x)/N; ac_i=x_i-mean; total_ms=sum(x_i^2)/N; ac_ms=sum(ac_i^2)/N; total_ms=mean^2+ac_ms",
  "expected": {
    "mean": 0.5,
    "ac_samples": [
      -0.5,
      0.5,
      -0.5,
      0.5
    ],
    "total_ms": 0.5,
    "ac_ms": 0.25,
    "total_rms": 0.7071067811865476,
    "ac_rms": 0.5
  },
  "negative_control": {
    "values": {
      "samples": [
        -0.5,
        0.5,
        -0.5,
        0.5
      ]
    },
    "expected": {
      "mean": 0,
      "ac_samples": [
        -0.5,
        0.5,
        -0.5,
        0.5
      ],
      "total_ms": 0.25,
      "ac_ms": 0.25,
      "total_rms": 0.5,
      "ac_rms": 0.5
    }
  }
}
```

## Choisir la grandeur avant de modifier le signal

La moyenne dépend de l’enregistrement choisi. Même un signal alternatif peut présenter une moyenne finie non nulle si la fenêtre coupe ses cycles de façon inégale. Y voir un défaut matériel demanderait d’autres preuves. Ici, cette moyenne est simplement la coordonnée constante des échantillons conservés. Le centrage décrit ces échantillons ; il faut le consigner comme transformation et garder aussi l’entrée intacte.

La décomposition s’obtient en écrivant chaque échantillon comme la somme de sa moyenne et de son reste centré. La moyenne du reste étant nulle, le terme croisé disparaît dans le cumul. L’identité concerne donc des grandeurs quadratiques. Elle explique aussi pourquoi une soustraction échantillon par échantillon réduit l’énergie calculée alors que la forme alternative reste identique. Un gain choisi ensuite d’après le niveau total initial modifierait cette forme alternative.

Pour la revue de source, dressez une table contenant échantillon original, moyenne, valeur centrée et contributions quadratiques. Ce calcul direct suffit à contester un rapport de niveau trompeur. Un nouveau nœud d’analyse ou un agent n’est utile que s’il conserve aussi clairement les bornes et l’historique des transformations. Avant tout traitement réel, précisez si l’expérience porte sur le tampon original, sa composante centrée ou la sortie d’un filtre défini : ce sont des artefacts distincts.

### Exercice 1

Calculez la moyenne et la séquence centrée. Pourquoi conserver les bornes de l’enregistrement ?

<details><summary>Réponse 1</summary>

La moyenne et la séquence alternative du cas principal figurent ci-dessus. Modifier les bornes modifie la moyenne ; ni un nom de fichier ni un contrôle de crête ne remplacent ce calcul.

</details>

### Exercice 2

Décomposez la moyenne des carrés. Faut-il soustraire les amplitudes efficaces ?

<details><summary>Réponse 2</summary>

Appliquez l’identité affichée aux moyennes des carrés. Le terme croisé s’annule puisque la somme de la séquence centrée est nulle. Soustraire les amplitudes efficaces donnerait un autre résultat.

</details>

### Exercice 3

Comparez les niveaux efficaces total et alternatif du cas principal. Lequel décrit la composante centrée ?

<details><summary>Réponse 3</summary>

Le niveau efficace alternatif décrit la composante centrée. Le niveau total comprend aussi la contribution constante ; son égalité ne garantit donc pas une même énergie alternative.

</details>

### Exercice 4

Appliquez le cas témoin. Quelle composante change et quelle comparaison reste valable ?

<details><summary>Réponse 4</summary>

La moyenne devient nulle, mais les échantillons centrés et leur niveau efficace restent identiques. Un rapport qui leur attribue une différence alternative confond les grandeurs.

</details>

### Exercice 5

Retirer cette moyenne valide-t-il la chaîne en continu ou le résultat d’écoute ?

<details><summary>Réponse 5</summary>

Non. Le centrage d’un enregistrement peut modifier ses extrémités et ne décrit pas le régime transitoire d’un filtre. L’implémentation en continu et le jugement d’écoute exigent leurs propres observations.

</details>

## Travail avec consultation des sources

Rédigez une note de comparaison pour le script. Calculez les décompositions à la main, puis repérez le cumul dans la source. Précisez si le gain proposé vise le niveau total ou alternatif. Rejetez un rapport qui change de dénominateur ou ne centre qu’une entrée sans le déclarer.

Conservez d’abord votre raisonnement sans aide, avant de révéler les réponses. Examinez ensuite un passage précis avec sa révision, consignez chaque aide reçue et gardez séparément la réponse initiale et sa correction. Votre résultat manuel sert de référence pour toute calculatrice, proposition de DSL ou intervention d’agent. Une donnée manquante reste non résolue. Le dossier contient un critère préparé par exercice, sans décision d’apprenant. Une réponse correcte ne justifie que le cas déclaré ; l’acceptation exige une tentative réelle et sa revue. Formulez un critère de réfutation avant toute abstraction, puis indiquez les preuves humaines ou d’exécution nécessaires à la prochaine étape.
