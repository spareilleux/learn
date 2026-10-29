---
title: Séparer erreur et biais avec un dither soustractif
description: Séparer erreur et biais avec un dither soustractif — Ingénierie audio
sidebar:
  label: AUD-025 · Séparer erreur et biais avec un dither soustractif
  order: 25
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/audio-engineering/fr/aud-025-separate-subtractive-dither-error-from-bias.fr.md
---

:::note[Streeling University]
**AUD-025** · Séparer erreur et biais avec un dither soustractif · avancé · 55 minutes

Généré par le département *Ingénierie audio* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/audio-engineering/fr/aud-025-separate-subtractive-dither-error-from-bias.fr.md) · [Mon journal](../../journal/)

Prérequis: [AUD-015](../../audio-engineering/aud-015-bound-quantization-error-before-comparing-wavs/)
:::

> Modèle fini construit et lecture bornée des sources. Les décisions techniques humaines, linguistiques, musicales et des apprenants restent en attente. Aucun nouveau rendu, essai d’écoute, jeu instrumental, parseur exécuté ni adoption en production n’est revendiqué.

Une proposition de dither peut confondre bruit ajouté et erreur résiduelle après soustraction du même décalage. Gardez ensemble les équations du codeur et du décodeur. Les décalages fixes forment un ensemble pédagogique fini, pas un générateur aléatoire ni un échantillon uniforme indépendant. Une moyenne nulle ici ne prouve pas l’indépendance pour toute entrée. Dans un futur export [GA](https://github.com/GuitarAlchemist/ga), perdre la correspondance des décalages changerait le convertisseur.

## Hypothèses et limites propres au cas

Utilisez un quantificateur non borné à pas unitaire avec l’arrondi affiché. Les décalages sont fixes, sans écrêtage ni tirage aléatoire. La table finie ne démontre ni densité de probabilité, ni indépendance, ni inaudibilité, ni export réel.

## Partir de la représentation directe

Écrivez la table principale avant de consulter les réponses préparées. Précisez pour chaque champ le repère, l’unité physique ou logique, le support et l’ordre. Une valeur privée de sa convention ne peut pas circuler fidèlement entre graphe audio, scène et message d’agent. Dérivez les grandeurs intermédiaires autant que la décision finale. Le paquet distingue volontairement entrées et résultats attendus : une autre personne doit pouvoir recalculer, pas seulement reconnaître une étiquette familière.

Répétez l’opération avec le témoin négatif en gardant visibles les entrées modifiées. Expliquez quel invariant subsiste et quelle affirmation échoue. Un témoin utile cible le mécanisme étudié ; un autre exemple simplement plausible peut ignorer la frontière risquée. L’accord du seul cas principal ne prouve pas qu’une abstraction conserve l’opération. À l’inverse, le rejet du témoin est un résultat prévu du modèle pédagogique, pas un défaut observé dans un produit existant.

Lisez le prérequis complet et l’artefact conservé ci-dessous. Le prérequis établit une opération antérieure avec ses limites. Le programme conservé fournit un vrai processus de comparaison audio et sépare échantillons bruts, sortie codée et décisions d’acceptation. Il n’implémente pas le nouveau modèle de ce cours. Les empreintes locales identifient les octets complets à la révision indiquée ; elles ne transforment pas une inspection en exécution. Une référence primaire liée ne soutient que la définition bornée consignée dans le paquet.

## Préparer une transmission de projet avec les sources

Rédigez une courte note de revue GA avec votre calcul manuel, la convention et le témoin de rejet. Gardez ce résultat direct comme référence avant de proposer un nœud DSL, une instruction d’agent ou un contrôle de scène. La proposition doit préciser les informations préservées en entrée et l’observation qui réfuterait sa fidélité. Si une entrée manque, laissez le résultat indécis au lieu d’inventer une valeur commode.

Conservez la réponse sans aide avant de révéler les corrections. Notez calculatrice, consultation de source et assistance d’agent, puis gardez correction et original avec l’explication du changement. Le paquet prépare un critère par exercice, sans décision d’acceptation d’apprenant. Retrouver un corrigé ne prouve ni rappel autonome ni essai réussi. Consignez commandes, entrées, sorties, échecs et reprises réellement exécutés dans le journal de validation. Revue technique humaine, revue linguistique, jugement musical, exécution en production et publication exigent chacun leurs propres éléments.

[Prérequis](../../audio-engineering/aud-015-bound-quantization-error-before-comparing-wavs/)

[Artefact de projet conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/run.mjs)

[Paquet construit fixe](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "x": 0,
    "dither": [
      -0.375,
      -0.125,
      0.125,
      0.375
    ],
    "subtract": true
  },
  "formula": "q=floor(x+d+0.5); decoded=q-d if subtract else q; errors=decoded-x; mean=sum(errors)/count; mse=sum(e*e)/count",
  "expected": {
    "encoded": [
      0,
      0,
      0,
      0
    ],
    "decoded": [
      0.375,
      0.125,
      -0.125,
      -0.375
    ],
    "errors": [
      0.375,
      0.125,
      -0.125,
      -0.375
    ],
    "mean": 0,
    "mse": 0.078125
  },
  "negative_control": {
    "values": {
      "x": 0.25,
      "dither": [
        -0.375,
        -0.125,
        0.125,
        0.375
      ],
      "subtract": false
    },
    "expected": {
      "encoded": [
        0,
        0,
        0,
        1
      ],
      "decoded": [
        0,
        0,
        0,
        1
      ],
      "errors": [
        -0.25,
        -0.25,
        -0.25,
        0.75
      ],
      "mean": 0,
      "mse": 0.1875
    }
  }
}
```

### Exercice 1

Calculez les valeurs décodées avec soustraction.

> **Réponse:** Elles valent `[0.375,0.125,-0.125,-0.375]`, même si tous les entiers codés valent 0.

### Exercice 2

Quelles sont la moyenne et l’erreur quadratique moyenne finies ?

> **Réponse:** La moyenne vaut 0 et l’erreur quadratique moyenne vaut 0.078125 pour cet ensemble fixe.

### Exercice 3

Cela établit-il un théorème d’indépendance stochastique ?

> **Réponse:** Non. Un ensemble déterministe à une entrée ne définit pas une distribution pour toute entrée.

### Exercice 4

Pourquoi la moyenne ne suffit-elle pas dans le témoin ?

> **Réponse:** Elle reste égale à 0 alors que l’erreur quadratique moyenne devient 0.1875 et que les erreurs individuelles changent.

### Exercice 5

Qu’est-ce qui réfute la récupération soustractive déclarée ?

> **Réponse:** Un décalage de décodage différent du décalage de codage réfute le contrat stipulé.

## Tâche d’apprenant avec les sources

Appliquez la transmission directe ci-dessus aux deux cas fixes. Conservez table d’entrée typée, résultats intermédiaires, explication du témoin négatif et témoin final de rejet. Les corrigés sont des vérifications préparées, pas des observations de votre travail.
