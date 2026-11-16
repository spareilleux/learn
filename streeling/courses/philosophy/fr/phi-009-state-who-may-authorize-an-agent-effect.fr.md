---
module_id: phi-009-state-who-may-authorize-an-agent-effect
department: philosophy
course: "Préciser qui peut autoriser l’effet d’un agent"
level: intermediate
prerequisites: ["phi-002-when-is-an-advisory-decision-justified", "phi-005-test-idempotence-beyond-replayed-values"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Préciser qui peut autoriser l’effet d’un agent

> Brouillon à soumettre à une relecture humaine. Les cas fixes ci-dessous sont des modèles mathématiques rédigés après lecture des sources ; ce ne sont pas de nouvelles mesures du projet. Les avis techniques, artisanaux, linguistiques et pédagogiques restent en attente. Aucun moteur de scène, échantillon physique, GPU, exécuteur de politique ni essai avec un apprenant n’a été utilisé pour cette leçon.

## Question du projet

Un avis Demerzel indique allow et un worker possède des identifiants capables de modifier un dépôt. Qui a autorisé l’effet ? Le schéma figé décrit explicitement un résultat consultatif et interdit la mutation par cette décision. Capacité, recommandation et autorisation sont des propositions distinctes. Nous modélisons un contrôle proposé pour réfuter l’inférence d’un test d’outil réussi vers une permission d’agir.

[Prérequis: phi-002-when-is-an-advisory-decision-justified](../../philosophy/en/phi-002-when-is-an-advisory-decision-justified.md); [Prérequis: phi-005-test-idempotence-beyond-replayed-values](../../philosophy/en/phi-005-test-idempotence-beyond-replayed-values.md)

## Lire le périmètre avant de calculer

Lisez le prérequis et le document du projet avant de calculer. Distinguez les affirmations tirées du code inspecté, les résultats consignés antérieurement et les conséquences des seules hypothèses ci-dessous. Un commentaire de code, un corrigé préparé et une observation exécutée n’ont pas la même valeur probante. Conservez la date d’origine ainsi que tout contrôle échoué ou non concluant dans votre résumé d’un ancien document. La référence manuelle est un petit calcul sur papier accompagné d’un tableau des emplacements dans les sources ; un agent peut aider à trouver une définition, mais son résumé doit être confronté à celle-ci. Ce cas fini ne nécessite aucun nouveau langage ni automatisme.

Supposons qu’un effet exige une instruction applicable d’une personne habilitée, un périmètre correspondant à l’effet demandé et une instruction encore valide au moment d’agir. L’acteur doit aussi avoir la capacité, qui ne peut remplacer une prémisse d’autorisation absente. Le modèle booléen omet authentification, courses de révocation et exécution : c’est seulement une aide au raisonnement. Liez l’autorité au dépôt, à l’effet et à la révision réels plutôt qu’à un libellé favorable. Une autorisation de rédiger un cours ne couvre pas forcément publication ou fusion. La confiance d’un conseiller ne change ni la personne habilitée ni le périmètre.

## Cas fixe et hypothèses

```text
permit=principal_authorized AND scope_matches AND still_valid
may_execute=permit AND capability
cases=[
 {"name":"advice_only","principal_authorized":false,"scope_matches":true,"still_valid":true,"capability":true},
 {"name":"wrong_scope","principal_authorized":true,"scope_matches":false,"still_valid":true,"capability":true},
 {"name":"revoked","principal_authorized":true,"scope_matches":true,"still_valid":false,"capability":true},
 {"name":"declared_permit","principal_authorized":true,"scope_matches":true,"still_valid":true,"capability":true}
]
may_execute_values=[false,false,false,true]
control_no_capability: permit=true; may_execute=false
```

## Exercices corrigés

### Exercice 1

Évaluez le cas limité à un avis.

> **Réponse:** Le résultat vaut `false` : capacité et recommandation favorable ne constituent pas l’instruction d’une personne habilitée.

### Exercice 2

Évaluez les cas de mauvais périmètre et de révocation.

> **Réponse:** Les deux valent `false`. Une identité correcte avec un effet hors périmètre, ou une instruction expirée, échoue au contrôle déclaré.

### Exercice 3

Quel cas construit permet l’exécution dans le modèle ?

> **Réponse:** Seul le cas declared-permit donne `true`. Ses prémisses booléennes sont fictives, pas la preuve d’une autorisation réelle de modifier le projet.

### Exercice 4

Retirez la capacité à un cas autorisé. Quelle distinction subsiste ?

> **Réponse:** La permission reste `true`, tandis que la possibilité d’exécuter vaut `false`. Le modèle distingue autorité et capacité pratique dans les deux sens.

### Exercice 5

Peut-on recopier allow dans un champ de permission de mutation ?

> **Réponse:** Non. Le contrat figé est consultatif et interdit la mutation. Un effet réel exige son processus d’autorisation applicable et des preuves actuelles ; cette leçon n’exécute aucun effet.

## Tâche assistée par les sources

Lisez la description de décision du schéma. Préparez manuellement un tableau acteur-effet-autorité pour une publication Learn hypothétique, sans l’exécuter. Faites classer les cas par une aide et gardez son raisonnement. Une recommandation traitée comme instruction habilitée réfute l’affirmation d’autorité.

Réalisez la tâche en masquant les corrigés. Gardez vos réponses initiales, les étapes de calcul, les emplacements dans les sources, les incertitudes et toutes les aides reçues, y compris un indice, un terme traduit ou une suggestion d’agent. Comparez ensuite avec les réponses préparées et consignez les corrections sans effacer votre premier essai. Rédigez une courte note de décision présentant l’affirmation, ses hypothèses, le calcul, le contrôle négatif et l’observation susceptible de la réfuter. Un résultat juste dépourvu d’unité ou d’identité de source ne suffit pas à démontrer le transfert. Le dossier comporte cinq critères préparés pour l’apprenant ; leur décision reste null tant qu’il n’existe pas d’essai réel et de relecture autorisée. La réussite de ces calculs établirait seulement une compétence sur le cas déclaré. Elle ne prouverait ni adaptateur opérationnel, ni procédé matériel réussi, ni moteur de rendu plus rapide, ni progrès d’apprentissage dans le projet. Comparez votre note assistée à la référence manuelle : si l’aide masque une hypothèse ou supprime un refus, corrigez la note avant de proposer un changement de méthode.

## Sources et journal de validation

- [Document du projet](../../../../code/streeling/evidence/representation-release-2026-10-22/phi002-schema-replay.json)
- [Source primaire](https://github.com/GuitarAlchemist/Demerzel/blob/9ba9a29f6424ac8c1a6654c9b979b282a8cf216f/schemas/advisory-decision.schema.json)
- [Dossier de preuves fixes](../../../../code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
