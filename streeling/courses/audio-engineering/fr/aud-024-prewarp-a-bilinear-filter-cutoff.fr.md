---
module_id: aud-024-prewarp-a-bilinear-filter-cutoff
department: audio-engineering
course: "Précompenser la fréquence de coupure bilinéaire"
level: advanced
prerequisites: ["aud-013-resample-without-relabeling-the-clock"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Précompenser la fréquence de coupure bilinéaire

> Modèle fini construit et lecture bornée des sources. Les décisions techniques humaines, linguistiques, musicales et des apprenants restent en attente. Aucun nouveau rendu, essai d’écoute, jeu instrumental, parseur exécuté ni adoption en production n’est revendiqué.

Une demande de filtre nomme une coupure numérique, tandis que le prototype analogique attend une fréquence angulaire. Recopier directement la fréquence demandée ignore la transformation bilinéaire. Inversez cette transformation avant de produire les coefficients d’un futur filtre de guitare. L’horloge choisie rend l’écart visible. La correspondance conserve une cible choisie, pas toutes les largeurs de bande en fréquence ordinaire ; le filtre complet demande encore ses spécifications.

## Hypothèses et limites propres au cas

L’horloge est positive et la cible est strictement comprise entre zéro et Nyquist. Utilisez le facteur bilinéaire déclaré et l’arctangente réelle principale. Il s’agit du calcul d’une correspondance fréquentielle, pas d’un générateur de coefficients exécuté.

## Partir de la représentation directe

Écrivez la table principale avant de consulter les réponses préparées. Précisez pour chaque champ le repère, l’unité physique ou logique, le support et l’ordre. Une valeur privée de sa convention ne peut pas circuler fidèlement entre graphe audio, scène et message d’agent. Dérivez les grandeurs intermédiaires autant que la décision finale. Le paquet distingue volontairement entrées et résultats attendus : une autre personne doit pouvoir recalculer, pas seulement reconnaître une étiquette familière.

Répétez l’opération avec le témoin négatif en gardant visibles les entrées modifiées. Expliquez quel invariant subsiste et quelle affirmation échoue. Un témoin utile cible le mécanisme étudié ; un autre exemple simplement plausible peut ignorer la frontière risquée. L’accord du seul cas principal ne prouve pas qu’une abstraction conserve l’opération. À l’inverse, le rejet du témoin est un résultat prévu du modèle pédagogique, pas un défaut observé dans un produit existant.

Lisez le prérequis complet et l’artefact conservé ci-dessous. Le prérequis établit une opération antérieure avec ses limites. Le programme conservé fournit un vrai processus de comparaison audio et sépare échantillons bruts, sortie codée et décisions d’acceptation. Il n’implémente pas le nouveau modèle de ce cours. Les empreintes locales identifient les octets complets à la révision indiquée ; elles ne transforment pas une inspection en exécution. Une référence primaire liée ne soutient que la définition bornée consignée dans le paquet.

## Préparer une transmission de projet avec les sources

Rédigez une courte note de revue [GA](https://github.com/GuitarAlchemist/ga) avec votre calcul manuel, la convention et le témoin de rejet. Gardez ce résultat direct comme référence avant de proposer un nœud DSL, une instruction d’agent ou un contrôle de scène. La proposition doit préciser les informations préservées en entrée et l’observation qui réfuterait sa fidélité. Si une entrée manque, laissez le résultat indécis au lieu d’inventer une valeur commode.

Conservez la réponse sans aide avant de révéler les corrections. Notez calculatrice, consultation de source et assistance d’agent, puis gardez correction et original avec l’explication du changement. Le paquet prépare un critère par exercice, sans décision d’acceptation d’apprenant. Retrouver un corrigé ne prouve ni rappel autonome ni essai réussi. Consignez commandes, entrées, sorties, échecs et reprises réellement exécutés dans le journal de validation. Revue technique humaine, revue linguistique, jugement musical, exécution en production et publication exigent chacun leurs propres éléments.

[Prérequis](../../audio-engineering/en/aud-013-resample-without-relabeling-the-clock.md)

[Artefact de projet conservé](../../../../code/streeling/guitar-runtime/run.mjs)

[Paquet construit fixe](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)

[Lecture primaire](https://www.dsprelated.com/freebooks/filters/Frequency_Warping.html)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "sample_rate_hz": 8,
    "target_hz": 2,
    "prewarp": true
  },
  "formula": "Omega=2*fs*tan(pi*target/fs) if prewarp else 2*pi*target; achieved=fs/pi*atan(Omega/(2*fs)); error=achieved-target",
  "expected": {
    "analog_rad_s": 16,
    "achieved_hz": 2,
    "error_hz": 0
  },
  "negative_control": {
    "values": {
      "sample_rate_hz": 8,
      "target_hz": 2,
      "prewarp": false
    },
    "expected": {
      "analog_rad_s": 12.566370614359172,
      "achieved_hz": 1.6953789327654465,
      "error_hz": -0.3046210672345535
    }
  }
}
```

### Exercice 1

Trouvez la cible analogique précompensée.

> **Réponse:** Elle vaut `16 rad/s` ; l’argument de la tangente est `pi/4`.

### Exercice 2

Ramenez-la à la fréquence numérique.

> **Réponse:** L’inverse donne `2 Hz` ; l’erreur à la cible choisie vaut donc 0.

### Exercice 3

Peut-on remplacer une fréquence angulaire par des hertz ?

> **Réponse:** Non. Les unités diffèrent ; le facteur de conversion appartient à la transformation déclarée.

### Exercice 4

Pourquoi le témoin naïf manque-t-il la cible ?

> **Réponse:** Sa valeur analogique `4*pi` est inférieure à 16 et la transformation croissante donne une coupure numérique plus basse.

### Exercice 5

Qu’est-ce qui réfute la coupure annoncée ?

> **Réponse:** Une fréquence obtenue différente de la cible conservée la réfute dans cette transformation.

## Tâche d’apprenant avec les sources

Appliquez la transmission directe ci-dessus aux deux cas fixes. Conservez table d’entrée typée, résultats intermédiaires, explication du témoin négatif et témoin final de rejet. Les corrigés sont des vérifications préparées, pas des observations de votre travail.
