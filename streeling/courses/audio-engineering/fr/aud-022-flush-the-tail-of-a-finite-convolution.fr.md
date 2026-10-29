---
module_id: aud-022-flush-the-tail-of-a-finite-convolution
department: audio-engineering
course: "Conserver la queue d’une convolution finie"
level: advanced
prerequisites: ["aud-011-count-valid-frames-separately-from-block-padding"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Conserver la queue d’une convolution finie

> Modèle fini construit et lecture bornée des sources. Les décisions techniques humaines, linguistiques, musicales et des apprenants restent en attente. Aucun nouveau rendu, essai d’écoute, jeu instrumental, parseur exécuté ni adoption en production n’est revendiqué.

Un rendu de guitare [GA](https://github.com/GuitarAlchemist/ga) peut épuiser son entrée alors que la réponse de baffle produit encore une sortie. Le support de la convolution finie dépasse celui de l’entrée. Qualifier tous les échantillons suivants de remplissage supprime une vraie queue. À l’inverse, une réponse finie ne demande pas une alimentation indéfinie en zéros. Construisez la table des indices avant de proposer un adaptateur de flux. Cette convolution est un exemple construit, pas un nouvel enregistrement.

L’opération ajoutée est la transition de fin d’entrée. Le calendrier fixe distingue `input` puis `flush`, conserve l’historique du plus récent au plus ancien et s’arrête quand le compte restant est nul. Un zéro de vidange ne crée pas un nouvel événement d’entrée. Arrêter faute d’entrée laisse un historique non vide et une sortie valide en attente. Le cours sur l’estimation de transfert identifie déjà une queue supprimée ; celui-ci explicite le protocole de vidange pour un futur adaptateur.

## Hypothèses et limites propres au cas

Utilisez des tableaux réels causaux non vides et un prolongement nul. Le support suit la convolution linéaire finie ; le compte émis doit rester dans ce support. Aucune capture de baffle ni aucun exporteur de flux n’a été exécuté.

## Partir de la représentation directe

Écrivez la table principale avant de consulter les réponses préparées. Précisez pour chaque champ le repère, l’unité physique ou logique, le support et l’ordre. Une valeur privée de sa convention ne peut pas circuler fidèlement entre graphe audio, scène et message d’agent. Dérivez les grandeurs intermédiaires autant que la décision finale. Le paquet distingue volontairement entrées et résultats attendus : une autre personne doit pouvoir recalculer, pas seulement reconnaître une étiquette familière.

Répétez l’opération avec le témoin négatif en gardant visibles les entrées modifiées. Expliquez quel invariant subsiste et quelle affirmation échoue. Un témoin utile cible le mécanisme étudié ; un autre exemple simplement plausible peut ignorer la frontière risquée. L’accord du seul cas principal ne prouve pas qu’une abstraction conserve l’opération. À l’inverse, le rejet du témoin est un résultat prévu du modèle pédagogique, pas un défaut observé dans un produit existant.

Lisez le prérequis complet et l’artefact conservé ci-dessous. Le prérequis établit une opération antérieure avec ses limites. Le programme conservé fournit un vrai processus de comparaison audio et sépare échantillons bruts, sortie codée et décisions d’acceptation. Il n’implémente pas le nouveau modèle de ce cours. Les empreintes locales identifient les octets complets à la révision indiquée ; elles ne transforment pas une inspection en exécution. Une référence primaire liée ne soutient que la définition bornée consignée dans le paquet.

## Préparer une transmission de projet avec les sources

Rédigez une courte note de revue GA avec votre calcul manuel, la convention et le témoin de rejet. Gardez ce résultat direct comme référence avant de proposer un nœud DSL, une instruction d’agent ou un contrôle de scène. La proposition doit préciser les informations préservées en entrée et l’observation qui réfuterait sa fidélité. Si une entrée manque, laissez le résultat indécis au lieu d’inventer une valeur commode.

Conservez la réponse sans aide avant de révéler les corrections. Notez calculatrice, consultation de source et assistance d’agent, puis gardez correction et original avec l’explication du changement. Le paquet prépare un critère par exercice, sans décision d’acceptation d’apprenant. Retrouver un corrigé ne prouve ni rappel autonome ni essai réussi. Consignez commandes, entrées, sorties, échecs et reprises réellement exécutés dans le journal de validation. Revue technique humaine, revue linguistique, jugement musical, exécution en production et publication exigent chacun leurs propres éléments.

[Prérequis](../../audio-engineering/en/aud-011-count-valid-frames-separately-from-block-padding.md)

[Artefact de projet conservé](../../../../code/streeling/guitar-runtime/run.mjs)

[Paquet construit fixe](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)

[Lecture primaire](https://www.dsprelated.com/freebooks/mdft/Convolution.html)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "x": [
      1,
      2
    ],
    "h": [
      1,
      0.5,
      0.25
    ],
    "emit_count": 4
  },
  "formula": "y[n]=sum(x[k]*h[n-k] for valid k and n-k); full_length=len(x)+len(h)-1; emitted=full[:emit_count]; lost=full[emit_count:]; after end of input feed exactly len(h)-1 flush frames; history is most recent len(h)-1 fed values newest first; stop at full_length, not at input exhaustion",
  "expected": {
    "full": [
      1,
      2.5,
      1.25,
      0.5
    ],
    "emitted": [
      1,
      2.5,
      1.25,
      0.5
    ],
    "lost": [],
    "complete": true,
    "phases": [
      "input",
      "input",
      "flush",
      "flush"
    ],
    "final_history": [
      0,
      0
    ],
    "pending_flush_frames": 0
  },
  "negative_control": {
    "values": {
      "x": [
        1,
        2
      ],
      "h": [
        1,
        0.5,
        0.25
      ],
      "emit_count": 2
    },
    "expected": {
      "full": [
        1,
        2.5,
        1.25,
        0.5
      ],
      "emitted": [
        1,
        2.5
      ],
      "lost": [
        1.25,
        0.5
      ],
      "complete": false,
      "phases": [
        "input",
        "input"
      ],
      "final_history": [
        2,
        1
      ],
      "pending_flush_frames": 2
    }
  }
}
```

### Exercice 1

Calculez la sortie complète.

> **Réponse:** Elle vaut `[1,2.5,1.25,0.5]` ; la dernière valeur combine les derniers coefficients de l’entrée et de la réponse.

### Exercice 2

Quelle sortie valide suit le support d’entrée ?

> **Réponse:** La queue compte 2 échantillons. Sa validité découle du support de convolution, indépendamment de la capacité du tampon.

### Exercice 3

Une entrée nulle après épuisement impose-t-elle une sortie immédiatement nulle ?

> **Réponse:** Non. Les entrées antérieures contribuent encore par les coefficients retardés de la réponse.

### Exercice 4

Que perd le témoin tronqué ?

> **Réponse:** Il perd `[1.25,0.5]` ; son vecteur émis ne représente donc pas la réponse complète.

### Exercice 5

Qu’est-ce qui réfute un export complet ?

> **Réponse:** Toute valeur non nulle omise dans le support complet déclaré réfute cette affirmation.

## Tâche d’apprenant avec les sources

Appliquez la transmission directe ci-dessus aux deux cas fixes. Conservez table d’entrée typée, résultats intermédiaires, explication du témoin négatif et témoin final de rejet. Les corrigés sont des vérifications préparées, pas des observations de votre travail.
