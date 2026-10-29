---
module_id: wml-021-find-common-partials-without-equating-fundamentals
department: world-music-languages
course: "Trouver les partiels communs sans égaliser les fondamentales"
level: advanced
prerequisites: ["wml-008-retain-register-in-drone-relative-intervals"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Trouver les partiels communs sans égaliser les fondamentales

> Modèle fini construit et lecture bornée des sources. Les décisions techniques humaines, linguistiques, musicales et des apprenants restent en attente. Aucun nouveau rendu, essai d’écoute, jeu instrumental, parseur exécuté ni adoption en production n’est revendiqué.

Des fondamentales différentes peuvent partager un partiel exact dans un modèle harmonique idéal. Construisez les deux inventaires finis en conservant les indices avant de chercher leur intersection. Une fréquence commune indique un composant commun du modèle, pas l’identité des notes ni leur appartenance à une tradition. La borne supérieure compte : une absence dans la liste finie ne prouve pas l’absence dans la série infinie. Cette opération explicite une explication de bourdon [GA](https://github.com/GuitarAlchemist/ga) sans perdre le registre ni remplacer une coïncidence acoustique par l’égalité de classes de hauteurs.

## Hypothèses et limites propres au cas

Les fondamentales sont des entiers positifs et les partiels des multiples harmoniques idéaux sous une borne finie. L’égalité est exacte. L’intersection ne représente ni incertitude, ni inharmonicité, ni jugement de consonance, ni interprétation culturelle.

## Partir de la représentation directe

Écrivez la table principale avant de consulter les réponses préparées. Précisez pour chaque champ le repère, l’unité physique ou logique, le support et l’ordre. Une valeur privée de sa convention ne peut pas circuler fidèlement entre graphe audio, scène et message d’agent. Dérivez les grandeurs intermédiaires autant que la décision finale. Le paquet distingue volontairement entrées et résultats attendus : une autre personne doit pouvoir recalculer, pas seulement reconnaître une étiquette familière.

Répétez l’opération avec le témoin négatif en gardant visibles les entrées modifiées. Expliquez quel invariant subsiste et quelle affirmation échoue. Un témoin utile cible le mécanisme étudié ; un autre exemple simplement plausible peut ignorer la frontière risquée. L’accord du seul cas principal ne prouve pas qu’une abstraction conserve l’opération. À l’inverse, le rejet du témoin est un résultat prévu du modèle pédagogique, pas un défaut observé dans un produit existant.

Lisez le prérequis complet et l’artefact conservé ci-dessous. Le prérequis établit une opération antérieure avec ses limites. Le programme conservé fournit un vrai processus de comparaison audio et sépare échantillons bruts, sortie codée et décisions d’acceptation. Il n’implémente pas le nouveau modèle de ce cours. Les empreintes locales identifient les octets complets à la révision indiquée ; elles ne transforment pas une inspection en exécution. Une référence primaire liée ne soutient que la définition bornée consignée dans le paquet.

## Préparer une transmission de projet avec les sources

Rédigez une courte note de revue GA avec votre calcul manuel, la convention et le témoin de rejet. Gardez ce résultat direct comme référence avant de proposer un nœud DSL, une instruction d’agent ou un contrôle de scène. La proposition doit préciser les informations préservées en entrée et l’observation qui réfuterait sa fidélité. Si une entrée manque, laissez le résultat indécis au lieu d’inventer une valeur commode.

Conservez la réponse sans aide avant de révéler les corrections. Notez calculatrice, consultation de source et assistance d’agent, puis gardez correction et original avec l’explication du changement. Le paquet prépare un critère par exercice, sans décision d’acceptation d’apprenant. Retrouver un corrigé ne prouve ni rappel autonome ni essai réussi. Consignez commandes, entrées, sorties, échecs et reprises réellement exécutés dans le journal de validation. Revue technique humaine, revue linguistique, jugement musical, exécution en production et publication exigent chacun leurs propres éléments.

[Prérequis](../../world-music-languages/en/wml-008-retain-register-in-drone-relative-intervals.md)

[Artefact de projet conservé](../../../../code/streeling/guitar-runtime/run.mjs)

[Paquet construit fixe](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)

[Lecture primaire](https://www.phys.unsw.edu.au/jw/strings.html)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "fundamentals_hz": [
      100,
      150
    ],
    "max_partial": 4
  },
  "formula": "partials_i=[(n,n*f_i) for n=1..max_partial]; common=[(freq,n_left,n_right) where frequencies exactly equal]",
  "expected": {
    "common": [
      [
        300,
        3,
        2
      ]
    ]
  },
  "negative_control": {
    "values": {
      "fundamentals_hz": [
        100,
        151
      ],
      "max_partial": 4
    },
    "expected": {
      "common": []
    }
  }
}
```

### Exercice 1

Calculez le résultat principal et nommez sa convention.

> **Réponse:** La fréquence commune vaut 300, avec les indices 3 et 2 ; les fondamentales restent différentes.

### Exercice 2

Quelle grandeur faut-il distinguer ?

> **Réponse:** Un partiel commun n’est ni une fondamentale commune ni une classe de hauteur égale ; les relations diffèrent.

### Exercice 3

Quelle hypothèse limite la conclusion ?

> **Réponse:** La borne finie et l’égalité exacte excluent les coïncidences ultérieures et les rapprochements approximatifs.

### Exercice 4

Expliquez le témoin négatif.

> **Réponse:** Le témoin 151 n’a aucune fréquence commune sous la borne conservée ; cela ne prouve pas une impossibilité infinie.

### Exercice 5

Quelle observation réfuterait la proposition ?

> **Réponse:** Un partiel déclaré commun sans indices concordants dans les deux inventaires réfute le rapport d’intersection.

## Tâche d’apprenant avec les sources

Appliquez la transmission directe ci-dessus aux deux cas fixes. Conservez table d’entrée typée, résultats intermédiaires, explication du témoin négatif et témoin final de rejet. Les corrigés sont des vérifications préparées, pas des observations de votre travail.
