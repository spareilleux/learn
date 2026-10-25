---
module_id: "inf-016-bind-a-delta-to-its-reference-state"
department: "information-theory"
course: "Lier un delta à son état de référence"
level: "intermediate"
prerequisites: ["inf-011-separate-compressed-size-from-preserved-information", "inf-014-retain-message-codebook-versions"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Lier un delta à son état de référence

> Ce cours utilise des entrées construites et des passages de sources consultés. Les nombres, historiques et étiquettes sont pédagogiques. La revue technique humaine, la relecture linguistique, les tentatives apprenantes, l’exécution, l’adoption en production et la publication restent indéterminées.

Un agent n’envoie que la variation d’un compteur Learn pour raccourcir son transfert. Le destinataire l’ajoute intacte à son propre compteur et obtient un total erroné. Les deux parties peuvent partager la même opération tout en partant d’états différents. La réversibilité dépend de la référence, pas du delta seul.

Le RFC 3284 distingue une différence relative à une source d’une compression sans source. Notre soustraction entière est une analogie construite, pas son format binaire. Calculez une seule fois le delta de l’émetteur, puis appliquez-le aux états des destinataires. Ne le recalculez pas après avoir vu la cible souhaitée.

Un identifiant de base immuable et fiable rend la précondition explicite. Le garde rejette une autre base au lieu de confondre une somme correcte avec l’état voulu. Dans un vrai système, cet identifiant exige lui-même intégrité et provenance. Une étiquette de hachage sans vérification des octets ne suffit pas. Ce cours propose une vérification de transfert sans créer de protocole de synchronisation.

## Sources et périmètre du projet

L’utilitaire Learn sépare métadonnées, titre et corps dans `parseModule` et indexe les noms anglais dans `englishModuleKeys`. Ces représentations permettent de nommer source et métadonnées ; elles n’implémentent pas l’opération construite. Le relevé de pratique distingue plutôt métriques de recherche et preuves apprenantes. Examinez le fichier lié et ne retenez que ce qu’il étaye réellement. Aucune entrée du modèle n’a été estimée à partir de ce fichier.

[Prérequis: inf-011-separate-compressed-size-from-preserved-information](../../information-theory/en/inf-011-separate-compressed-size-from-preserved-information.md)

[Prérequis: inf-014-retain-message-codebook-versions](../../information-theory/en/inf-014-retain-message-codebook-versions.md)

[Artefact conservé du projet](../../../../scripts/streeling-lib.mjs)

[Artefact conservé du projet](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lecture primaire](https://www.rfc-editor.org/rfc/rfc3284.html)

## Modèle fixé et contrôle

```json
{
  "values": {
    "sender_base_id": "b1",
    "sender_base": 10,
    "target": 13,
    "receiver_base_id": "b1",
    "receiver_base": 10
  },
  "formula": "delta=target-sender_base; naive=receiver_base+delta; accept iff receiver_base_id==sender_base_id; guarded reconstruction is naive if accepted else null.",
  "expected": {
    "delta": 3,
    "naive_reconstruction": 13,
    "accepted": true,
    "guarded_reconstruction": 13
  },
  "negative_control": {
    "values": {
      "sender_base_id": "b1",
      "sender_base": 10,
      "target": 13,
      "receiver_base_id": "b2",
      "receiver_base": 20
    },
    "expected": {
      "delta": 3,
      "naive_reconstruction": 23,
      "accepted": false,
      "guarded_reconstruction": null
    },
    "why": "An intact delta added to another base produces another value; a base-identity guard rejects it."
  },
  "assumptions": [
    "Integers exact; each trusted base identity denotes one immutable value.",
    "No overflow, missing delta or transport corruption."
  ],
  "limits": "Toy scalar differencing, not VCDIFF encoding, authentic identity or production synchronization.",
  "input_types": {
    "sender_base_id": "string",
    "sender_base": "integer",
    "target": "integer",
    "receiver_base_id": "string",
    "receiver_base": "integer"
  }
}
```

### Exercice 1

Calculez le delta de l’émetteur.

<details><summary>Réponse 1</summary>

`13-10=3`. Le delta décrit une relation à sa base ; ce n’est pas la valeur cible seule.

</details>

### Exercice 2

Reconstruisez avec la base correspondante.

<details><summary>Réponse 2</summary>

`10+3=13` ; les identifiants concordent, donc `accepted=true` et la reconstruction gardée vaut `13`.

</details>

### Exercice 3

Appliquez le contrôle à base différente.

<details><summary>Réponse 3</summary>

L’addition naïve donne `20+3=23`, mais `accepted=false` et la reconstruction gardée vaut `null`. La base différente reste le motif.

</details>

### Exercice 4

Une somme de contrôle du delta détecterait-elle cela ?

<details><summary>Réponse 4</summary>

Non. Le delta peut être intact avec une autre référence. Conservez l’identité de la base et vérifiez son état associé.

</details>

### Exercice 5

L’égalité des bases autorise-t-elle la mise à jour ?

<details><summary>Réponse 5</summary>

Non. Cette précondition arithmétique ne fournit ni autorité ni mise à jour atomique. Il faut d’autres contrats et preuves.

</details>

## Travail avec consultation des sources

Préparez une fiche d’état de référence pour des compteurs Learn fictifs et soumettez une mauvaise base à un assistant.

**Référence manuelle directe:** Soustrayez la base émettrice, puis ajoutez le delta inchangé aux bases réceptrices indiquées.

**Critère de réfutation:** Une base différente produit une cible acceptée ou le destinataire recalcule discrètement le delta.

Enregistrez une première réponse avant d’ouvrir les corrigés. Recopiez les identités et unités des entrées, écrivez les étapes intermédiaires et distinguez calcul et interprétation. Un nombre juste avec un dénominateur, une frontière d’état ou une unité de comptage erronés ne satisfait pas la tâche. Conservez un résultat surprenant au lieu de modifier l’entrée pour rendre la réponse plausible.

Lisez le passage primaire cité dans le périmètre indiqué au dossier. Comparez sa définition à la règle construite du modèle. La référence peut motiver un concept sans spécifier tout notre modèle. Notez version ou date, passage utilisé et hypothèse importée. L’accès à une page ou la lecture réussie d’un fichier ne vérifie pas une affirmation.

Examinez l’artefact conservé et un prérequis. Séparez ce que représente réellement le fichier de ce que cette nouvelle tâche suppose. Gardez révision et historique des aides. Après avoir enregistré la référence manuelle, demandez à un assistant de contester une hypothèse. Conservez consigne, réponse, correction retenue et suggestion rejetée. Sources et calculatrice sont des aides autorisées, pas du rappel sans assistance.

Traitez l’entrée modifiée avec le même raisonnement sur papier. Énoncez le critère de réfutation avant de proposer une abstraction d’agent ou une expression DSL composable. Si l’abstraction perd le contre-exemple ou change le point d’évaluation accepté, elle échoue même en étant plus courte. Comparez d’abord un tableau direct ou un enregistrement typé ; aucun nouveau langage ni moteur de production n’est nécessaire.

Remettez réponses initiale et corrigée, contrôle, passage source et incertitudes restantes. Le dossier prépare un critère distinct par exercice ; toutes les décisions apprenantes restent indéterminées. Corrigé, empreinte d’octets et vérification d’auteur diffèrent d’une tentative réelle. Une comparaison future en dogfood doit conserver les tentatives sur la même tâche versionnée et la référence directe avant d’annoncer un progrès utile.

[Dossier fixé](../../../../code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
