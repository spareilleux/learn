---
title: Distinguer amplitude et phase d’un filtre passe-tout
description: Distinguer amplitude et phase d’un filtre passe-tout — Ingénierie audio
sidebar:
  label: AUD-023 · Distinguer amplitude et phase d’un filtre passe-tout
  order: 23
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/audio-engineering/fr/aud-023-distinguish-allpass-magnitude-from-phase.fr.md
---

:::note[Streeling University]
**AUD-023** · Distinguer amplitude et phase d’un filtre passe-tout · avancé · 55 minutes

Généré par le département *Ingénierie audio* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/audio-engineering/fr/aud-023-distinguish-allpass-magnitude-from-phase.fr.md) · [Mon journal](../../journal/)

Prérequis: [AUD-008](../../audio-engineering/aud-008-measure-a-filter-with-paired-input-and-output/)
:::

> Modèle fini construit et lecture bornée des sources. Les décisions techniques humaines, linguistiques, musicales et des apprenants restent en attente. Aucun nouveau rendu, essai d’écoute, jeu instrumental, parseur exécuté ni adoption en production n’est revendiqué.

Une superposition de spectres d’amplitude peut faire passer un étage passe-tout pour l’identité. Numérateur et dénominateur ont le même module sur le cercle unité, mais leur quotient complexe modifie la phase. Dans une boucle de guitare, cette phase peut changer l’accord malgré une amplitude plate. Comparez la réponse complexe à une dérivation directe avant de proposer une composition transparente. Un témoin fréquentiel ne mesure pas l’effet audible sur une attaque.

## Hypothèses et limites propres au cas

Le coefficient réel a un module inférieur à l’unité, ce qui stabilise le pôle déclaré. Évaluez une réponse complexe établie sans en déduire l’énergie d’une impulsion tronquée ni une transparence audible. Aucun filtre compilé ni accord de boucle n’a été testé.

## Partir de la représentation directe

Écrivez la table principale avant de consulter les réponses préparées. Précisez pour chaque champ le repère, l’unité physique ou logique, le support et l’ordre. Une valeur privée de sa convention ne peut pas circuler fidèlement entre graphe audio, scène et message d’agent. Dérivez les grandeurs intermédiaires autant que la décision finale. Le paquet distingue volontairement entrées et résultats attendus : une autre personne doit pouvoir recalculer, pas seulement reconnaître une étiquette familière.

Répétez l’opération avec le témoin négatif en gardant visibles les entrées modifiées. Expliquez quel invariant subsiste et quelle affirmation échoue. Un témoin utile cible le mécanisme étudié ; un autre exemple simplement plausible peut ignorer la frontière risquée. L’accord du seul cas principal ne prouve pas qu’une abstraction conserve l’opération. À l’inverse, le rejet du témoin est un résultat prévu du modèle pédagogique, pas un défaut observé dans un produit existant.

Lisez le prérequis complet et l’artefact conservé ci-dessous. Le prérequis établit une opération antérieure avec ses limites. Le programme conservé fournit un vrai processus de comparaison audio et sépare échantillons bruts, sortie codée et décisions d’acceptation. Il n’implémente pas le nouveau modèle de ce cours. Les empreintes locales identifient les octets complets à la révision indiquée ; elles ne transforment pas une inspection en exécution. Une référence primaire liée ne soutient que la définition bornée consignée dans le paquet.

## Préparer une transmission de projet avec les sources

Rédigez une courte note de revue [GA](https://github.com/GuitarAlchemist/ga) avec votre calcul manuel, la convention et le témoin de rejet. Gardez ce résultat direct comme référence avant de proposer un nœud DSL, une instruction d’agent ou un contrôle de scène. La proposition doit préciser les informations préservées en entrée et l’observation qui réfuterait sa fidélité. Si une entrée manque, laissez le résultat indécis au lieu d’inventer une valeur commode.

Conservez la réponse sans aide avant de révéler les corrections. Notez calculatrice, consultation de source et assistance d’agent, puis gardez correction et original avec l’explication du changement. Le paquet prépare un critère par exercice, sans décision d’acceptation d’apprenant. Retrouver un corrigé ne prouve ni rappel autonome ni essai réussi. Consignez commandes, entrées, sorties, échecs et reprises réellement exécutés dans le journal de validation. Revue technique humaine, revue linguistique, jugement musical, exécution en production et publication exigent chacun leurs propres éléments.

[Prérequis](../../audio-engineering/aud-008-measure-a-filter-with-paired-input-and-output/)

[Artefact de projet conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/run.mjs)

[Paquet construit fixe](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)

[Lecture primaire](https://www.dsprelated.com/freebooks/filters/Allpass_Filters.html)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "a": 0.5,
    "omega_over_pi": 0.5,
    "numerator_scale": 1
  },
  "formula": "z_inv=exp(-j*pi*omega_over_pi); H=numerator_scale*(a+z_inv)/(1+a*z_inv); magnitude=abs(H)",
  "expected": {
    "H_real": 0.8,
    "H_imag": -0.6,
    "magnitude": 1,
    "identity": false
  },
  "negative_control": {
    "values": {
      "a": 0.5,
      "omega_over_pi": 0.5,
      "numerator_scale": 2
    },
    "expected": {
      "H_real": 1.6,
      "H_imag": -1.2,
      "magnitude": 2,
      "identity": false
    }
  }
}
```

### Exercice 1

Calculez la réponse complexe.

> **Réponse:** Elle vaut `0.8-0.6j`, de module 1, avec une partie imaginaire non nulle.

### Exercice 2

Pourquoi le même module ne suffit-il pas ?

> **Réponse:** L’identité exige aussi une réponse complexe égale à 1 ; la composante imaginaire affichée la réfute.

### Exercice 3

Quelle expression établit le module constant ?

> **Réponse:** Les deux modules au carré valent `1+a*a+2*a*cos(omega)` avant le facteur supplémentaire du numérateur.

### Exercice 4

Que montre le témoin amplifié ?

> **Réponse:** Son module vaut 2 ; la stabilité du pôle inchangé ne certifie donc pas un module passe-tout.

### Exercice 5

Qu’est-ce qui réfute la transparence de la dérivation ?

> **Réponse:** Une réponse complexe différente de l’identité à une fréquence admise réfute l’identité universelle.

## Tâche d’apprenant avec les sources

Appliquez la transmission directe ci-dessus aux deux cas fixes. Conservez table d’entrée typée, résultats intermédiaires, explication du témoin négatif et témoin final de rejet. Les corrigés sont des vérifications préparées, pas des observations de votre travail.
