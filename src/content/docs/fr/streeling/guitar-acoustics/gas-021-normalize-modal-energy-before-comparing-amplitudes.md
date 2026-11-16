---
title: Normaliser l’énergie modale avant de comparer les amplitudes
description: Normaliser l’énergie modale avant de comparer les amplitudes — Acoustique de la guitare et synthèse sonore
sidebar:
  label: GAS-021 · Normaliser l’énergie modale avant de comparer les amplitudes
  order: 21
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-acoustics/fr/gas-021-normalize-modal-energy-before-comparing-amplitudes.fr.md
---

:::note[Streeling University]
**GAS-021** · Normaliser l’énergie modale avant de comparer les amplitudes · avancé · 55 minutes

Généré par le département *Acoustique de la guitare et synthèse sonore* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-acoustics/fr/gas-021-normalize-modal-energy-before-comparing-amplitudes.fr.md) · [Mon journal](../../journal/)

Prérequis: [GAS-015](../../guitar-acoustics/gas-015-separate-mode-excitation-from-observation/)
:::

> Modèle fini construit et lecture bornée des sources. Les décisions techniques humaines, linguistiques, musicales et des apprenants restent en attente. Aucun nouveau rendu, essai d’écoute, jeu instrumental, parseur exécuté ni adoption en production n’est revendiqué.

Le coefficient d’un mode de guitare dépend de la normalisation de sa forme. Comparer des coefficients sans la masse modale peut inverser un classement énergétique. Intégrez le carré du sinus sur une corde uniforme idéale, puis conservez le déplacement généralisé et le déplacement normalisé par la masse. Le déplacement physique doit rester inchangé lors du changement de coordonnées. Un rapport [GA](https://github.com/GuitarAlchemist/ga) doit préciser la normalisation avant de comparer les énergies. Le calcul porte sur une énergie mécanique idéale, pas sur une amplitude de capteur ni un jugement sonore.

## Hypothèses et limites propres au cas

La corde est uniforme et emploie des modes sinus entiers normalisés en crête, dans des unités mécaniques cohérentes. Au retournement, la vitesse s’annule. C’est une énergie modale, sans gain de capteur étalonné, rayonnement acoustique ni amortissement de guitare mesuré.

## Partir de la représentation directe

Écrivez la table principale avant de consulter les réponses préparées. Précisez pour chaque champ le repère, l’unité physique ou logique, le support et l’ordre. Une valeur privée de sa convention ne peut pas circuler fidèlement entre graphe audio, scène et message d’agent. Dérivez les grandeurs intermédiaires autant que la décision finale. Le paquet distingue volontairement entrées et résultats attendus : une autre personne doit pouvoir recalculer, pas seulement reconnaître une étiquette familière.

Répétez l’opération avec le témoin négatif en gardant visibles les entrées modifiées. Expliquez quel invariant subsiste et quelle affirmation échoue. Un témoin utile cible le mécanisme étudié ; un autre exemple simplement plausible peut ignorer la frontière risquée. L’accord du seul cas principal ne prouve pas qu’une abstraction conserve l’opération. À l’inverse, le rejet du témoin est un résultat prévu du modèle pédagogique, pas un défaut observé dans un produit existant.

Lisez le prérequis complet et l’artefact conservé ci-dessous. Le prérequis établit une opération antérieure avec ses limites. Le programme conservé fournit un vrai processus de comparaison audio et sépare échantillons bruts, sortie codée et décisions d’acceptation. Il n’implémente pas le nouveau modèle de ce cours. Les empreintes locales identifient les octets complets à la révision indiquée ; elles ne transforment pas une inspection en exécution. Une référence primaire liée ne soutient que la définition bornée consignée dans le paquet.

## Préparer une transmission de projet avec les sources

Rédigez une courte note de revue GA avec votre calcul manuel, la convention et le témoin de rejet. Gardez ce résultat direct comme référence avant de proposer un nœud DSL, une instruction d’agent ou un contrôle de scène. La proposition doit préciser les informations préservées en entrée et l’observation qui réfuterait sa fidélité. Si une entrée manque, laissez le résultat indécis au lieu d’inventer une valeur commode.

Conservez la réponse sans aide avant de révéler les corrections. Notez calculatrice, consultation de source et assistance d’agent, puis gardez correction et original avec l’explication du changement. Le paquet prépare un critère par exercice, sans décision d’acceptation d’apprenant. Retrouver un corrigé ne prouve ni rappel autonome ni essai réussi. Consignez commandes, entrées, sorties, échecs et reprises réellement exécutés dans le journal de validation. Revue technique humaine, revue linguistique, jugement musical, exécution en production et publication exigent chacun leurs propres éléments.

[Prérequis](../../guitar-acoustics/gas-015-separate-mode-excitation-from-observation/)

[Artefact de projet conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/run.mjs)

[Paquet construit fixe](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)

[Lecture primaire](https://www.phys.unsw.edu.au/jw/strings.html)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "linear_density": 2,
    "length": 3,
    "omega": 4,
    "amplitude": 0.5,
    "assumed_modal_mass": null
  },
  "formula": "m_eff=mu*L/2 for sine peak normalization; E=0.5*m_eff*omega^2*A^2; q=sqrt(m_eff)*A; reported_E=0.5*used_mass*omega^2*A^2",
  "expected": {
    "modal_mass": 3,
    "mass_normalized_amplitude": 0.8660254037844386,
    "energy": 6,
    "reported_energy": 6
  },
  "negative_control": {
    "values": {
      "linear_density": 2,
      "length": 3,
      "omega": 4,
      "amplitude": 0.5,
      "assumed_modal_mass": 6
    },
    "expected": {
      "modal_mass": 3,
      "mass_normalized_amplitude": 0.8660254037844386,
      "energy": 6,
      "reported_energy": 12
    }
  }
}
```

### Exercice 1

Calculez le résultat principal et nommez sa convention.

> **Réponse:** La masse effective vaut 3 et l’énergie au point de retournement vaut 6 ; le sinus a un ventre unitaire.

### Exercice 2

Quelle grandeur faut-il distinguer ?

> **Réponse:** L’amplitude généralisée vaut 0.5 ; l’amplitude normalisée vaut `sqrt(3)/2`. Ce sont des coordonnées différentes du même déplacement.

### Exercice 3

Quelle hypothèse limite la conclusion ?

> **Réponse:** Le sinus et la densité uniforme donnent l’intégrale de masse ; des modes de caisse demandent leurs propres formes et matrice.

### Exercice 4

Expliquez le témoin négatif.

> **Réponse:** La masse supposée 6 donne une énergie annoncée de 12, alors que l’énergie correcte reste 6.

### Exercice 5

Quelle observation réfuterait la proposition ?

> **Réponse:** Un changement de base qui modifie déplacement reconstruit ou énergie réfute une conversion censée préserver la normalisation.

## Tâche d’apprenant avec les sources

Appliquez la transmission directe ci-dessus aux deux cas fixes. Conservez table d’entrée typée, résultats intermédiaires, explication du témoin négatif et témoin final de rejet. Les corrigés sont des vérifications préparées, pas des observations de votre travail.
