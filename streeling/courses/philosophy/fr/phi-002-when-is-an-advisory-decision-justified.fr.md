---
module_id: phi-002-when-is-an-advisory-decision-justified
department: philosophy
course: "Philosophie : preuves et autorité dans les décisions consultatives"
level: intermediate
alchemical_stage: albedo
prerequisites: [phi-001-how-to-argue-well]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
research_cycle: philosophy-2026-10-11-002
version: "0.1.0"
---

# Quand une décision consultative est-elle justifiée ?

> **Périmètre de la source et du transfert.** Le texte technique ci-dessous provient d’un brouillon archivé. Les mentions historiques de traductions encore à rédiger, d’une absence d’importation ou de compilation dans Learn concernent cette étape antérieure ; ce [dossier de transfert](../../../../code/streeling/evidence/representation-release-2026-10-22/README.md) décrit les brouillons de traduction actuels, l’importation et ses vérifications. Les autres expériences indiquées comme non réalisées le restent. Les revues humaines du contenu et de la langue, ainsi que l’essai avec un apprenant, restent à effectuer.

> **Département de philosophie** | Niveau : intermédiaire | Étape : Albedo | Durée : 35 minutes | Brouillon français en attente de révision du contenu, d'essai par un apprenant et de révision linguistique humaine

## Objectifs

Après cette leçon, vous saurez distinguer la conformité à un schéma d'un conseil justifié, repérer les divergences de vocabulaire d'un contrat, préciser qui conserve l'autorité de fusion et concevoir une vérification de preuve réfutable.

## Question du projet et périmètre des preuves

**Quand Demerzel peut-il recommander qu'une pull request Guitar Alchemist (GA) est prête pour une fusion humaine ?** Le [document sur les décisions consultatives](https://github.com/GuitarAlchemist/Demerzel/blob/9ba9a29f6424ac8c1a6654c9b979b282a8cf216f/docs/architecture/demerzel-advisory-decisions.md) de Demerzel indique que les recommandations doivent citer des identifiants précis d'événements Streeling ou de faits Seldon, donner des raisons et réserver les actions à haut risque comme la fusion à un humain. Son [schéma `advisory-decision`](https://github.com/GuitarAlchemist/Demerzel/blob/9ba9a29f6424ac8c1a6654c9b979b282a8cf216f/schemas/advisory-decision.schema.json) définit un résultat de règle structuré, en simulation. Le [document sur les ensembles de règles AIW](https://github.com/GuitarAlchemist/Demerzel/blob/9ba9a29f6424ac8c1a6654c9b979b282a8cf216f/docs/governance/aiw-rule-packs.md) qualifie explicitement le moteur d'évaluation de règles de consultatif, et non d'environnement d'exécution de production ou de remplacement du jugement humain. Les trois liens fixent le commit Demerzel `9ba9a29f6424ac8c1a6654c9b979b282a8cf216f`.

C'est une question philosophique avec une réponse opérationnelle. Une décision peut avoir une *forme* valide sans que ses raisons disposent de preuves pertinentes. Un conseil ne confère pas le pouvoir d'agir. [PHI-001](phi-001-how-to-argue-well.md) introduisait prémisses, conclusions et solidité des arguments ; ici, nous examinons les étapes entre une déclaration sérialisée, les preuves qui la soutiennent et une personne habilitée à décider. Nous testons un exemple **synthétique**, pas un moteur de politique actif ni une PR GA.

## 1. Un enregistrement peut être conforme sans étayer son affirmation

Le schéma exige un objet `rule_result` au premier niveau. À l'intérieur, `rule_id`, `subject`, `decision`, `reason_codes`, `evidence_refs`, `next_actions` et `confidence` sont obligatoires. `subject` peut être `pull_request` et `decision` peut être `recommend`. Toutefois, la propriété `evidence_refs` n'est qu'un tableau de chaînes : le schéma n'impose ni nombre minimal d'éléments, ni identifiant Streeling ou Seldon, ni règle reliant une référence à la PR nommée. Exiger un champ ne signifie pas exiger qu'il contienne une preuve utile.

Considérons cette **fixture pédagogique synthétique**. `PR-EXAMPLE` est une valeur fictive, pas une pull request observée ; l'identifiant de règle et l'action sont inventés uniquement pour sonder le schéma.

```json
{
  "rule_result": {
    "rule_id": "SYNTHETIC-PR-READINESS",
    "subject": "pull_request",
    "decision": "recommend",
    "reason_codes": [],
    "evidence_refs": [],
    "next_actions": ["ask a human to inspect PR-EXAMPLE"],
    "confidence": "high"
  }
}
```

Cet objet passe le JSON Schema figé : les clés requises existent, chaque valeur a un type autorisé, et `recommend` et `high` appartiennent à leurs énumérations respectives. C'est un résultat limité et reproductible sur la *structure*. Aucune source n'étaye l'affirmation selon laquelle PR-EXAMPLE aurait passé les contrôles CI, de révision ou de politique. Une liste vide ne satisfait pas le principe de preuve déclaré dans le document consultatif. Le schéma ne vérifie pas non plus qu'une chaîne non vide désigne un véritable événement. Qualifier la fixture de « confiance élevée » ajoute une étiquette, pas une preuve.

### Exercice 1 — Distinguer les trois tests

La fixture synthétique (a) est-elle conforme au schéma, (b) satisfait-elle le principe de preuve précise du document consultatif et (c) autorise-t-elle une fusion GA ? Citez les champs ou phrases qui déterminent chaque réponse.

> **Réponse :** (a) Oui. Elle contient toutes les clés `rule_result` requises, avec les valeurs autorisées `pull_request`, `recommend` et `high` ; le schéma permet des tableaux vides. (b) Non. `evidence_refs: []` ne contient aucun identifiant précis d'événement Streeling ou de fait Seldon. (c) Non. Le document réserve la fusion à une approbation humaine, et le document sur les ensembles de règles qualifie ce moteur de consultatif et de simulation. Un objet valide n'est ni une conclusion étayée de préparation ni une autorisation de fusion.

## 2. Une preuve exige une identité, une pertinence et une date

Supposons qu'un futur enregistrement mentionne `"ci-run-123"` dans `evidence_refs`. Un réviseur peut-il retrouver cette exécution, la faire correspondre à la révision exacte de la PR et vérifier son résultat final ? Un contrôle vert sur un ancien commit peut être authentique, mais sans pertinence pour le head actuel.

Pour une recommandation de fusion, le document consultatif exige la réussite de tous les contrôles de gouvernance, notamment CI, révision et politique. Le schéma cité ne comporte aucun champ dédié au numéro de PR, au SHA de head, à l'état CI, à l'approbation de révision ou au résultat de politique. Un producteur pourrait placer des chaînes explicatives dans `reason_codes` ou `evidence_refs`, mais cette seule structure ne peut pas démontrer que les contrôles requis ont été effectués. Un humain aurait besoin d'enregistrements datés correspondant à la cible et d'une correspondance documentée entre chaque contrôle et sa preuve. La décision pourrait alors être bien étayée ; elle resterait une recommandation.

« Tous les contrôles ont réussi » est une affirmation empirique sur une révision et un instant. « Prêt à fusionner » applique aussi une norme de politique. « Fusionnez » demande à un acteur habilité d'agir. Si un contrôle manque, consignez un contrôle non résolu ou demandez une révision. Le [catalogue des ensembles de règles](https://github.com/GuitarAlchemist/Demerzel/blob/9ba9a29f6424ac8c1a6654c9b979b282a8cf216f/docs/governance/aiw-rule-packs.md) mentionne Merge Readiness, mais ne montre pas qu'une PR particulière a été évaluée.

### Exercice 2 — Auditer une citation proposée

Un avis **synthétique** renvoie à `ci-run-123` et dit « GA PR-EXAMPLE est prête ». Énumérez trois faits que le réviseur doit vérifier avant de traiter cette référence comme preuve pour la partie CI de l'affirmation. Une exécution CI réussie établit-elle à elle seule toute l'affirmation de préparation ?

> **Réponse :** Retrouvez `ci-run-123` et vérifiez son existence ; confirmez que son dépôt, sa PR, son SHA de head et sa date correspondent à la révision jugée ; confirmez que l'exécution s'est terminée avec les contrôles requis réussis. La réussite CI seule n'établit pas les contrôles de révision et de politique, que le document consultatif inclut aussi dans la préparation à la fusion. La fixture ne fournit aucun véritable résultat CI.

## 3. Un contrat documenté peut diverger entre artefacts

Les artefacts figés utilisent des vocabulaires différents. Le document consultatif donne `route`, `hold`, `request_review`, `escalate`, `recommend_merge` et `no_action` comme types de décision. L'énumération `decision` du schéma contient `allow`, `block`, `warn`, `escalate` et `recommend`. La valeur littérale `recommend_merge` du document échoue donc à la validation du schéma, tandis que `recommend`, valide selon le schéma, ne précise pas à lui seul une recommandation de fusion. Ne traitez pas silencieusement les deux termes comme identiques.

Le document demande un score de confiance numérique de 0 à 1 et parle d'un champ `reasons`. Le schéma exige au contraire une chaîne catégorielle `confidence` (`low`, `medium` ou `high`) et `reason_codes`. Une valeur numérique `0.9` ou une clé `reasons` seule ne constitue pas l'objet décrit par le schéma. L'exemple du document sur les ensembles de règles utilise le vocabulaire du schéma. Ces observations établissent une *divergence documentée du contrat à cette révision*. Elles n'établissent ni quel artefact un service actif suit, ni l'existence éventuelle d'une migration ailleurs, ni qu'une décision de production était mal formée.

La règle en prose, le schéma lisible par machine et la décision particulière sont des objets distincts. Lorsqu'ils divergent, conservez la question pour les responsables du contrat ; une traduction inventée empêche une révision reproductible.

### Exercice 3 — Identifier la divergence exacte

Parmi les champs ou valeurs littéraux suivants, lesquels appartiennent au schéma figé : `decision: "recommend_merge"`, `decision: "recommend"`, `confidence: 0.9`, `confidence: "high"`, `reasons` et `reason_codes` ? Quelle conclusion peut-on tirer de l'incompatibilité ?

> **Réponse :** Le schéma accepte `decision: "recommend"`, `confidence: "high"` et le champ requis `reason_codes`. Il rejette la valeur littérale d'énumération `recommend_merge` et la confiance numérique, et `reasons` seul ne peut pas remplacer le champ requis `reason_codes`. Les documents divergent dans leur vocabulaire à la révision figée. Cela établit un problème de lecture du contrat, pas un comportement observé du moteur actif ni une permission d'assimiler leurs termes.

## 4. Le conseil et l'autorité sont distincts

Utilisons un second **scénario synthétique** : PR-EXAMPLE modifie un composant GA ; le réviseur dispose d'une exécution CI pour un ancien SHA de head, n'a aucune approbation de révision pour le head actuel et n'a pas trouvé de résultat de politique. Il serait injustifié de présenter cette PR comme prête. Le document consultatif mentionne explicitement une attente en cas d'échec CI ou de preuves manquantes, ainsi qu'une demande de révision. Le schéma peut représenter un avertissement ou une escalade, tandis que `next_actions` peut décrire les étapes humaines nécessaires. Le choix du code de règle exact dépendrait d'un ensemble de règles défini, que cette leçon n'a pas exécuté. L'objectif est de consigner la lacune plutôt que de déduire une réussite du silence.

L'autorité ajoute une autre frontière. Les actions interdites dans le MVP par le document consultatif comprennent la fusion automatique, le push direct de code, la modification des protections de branche et l'octroi de permissions aux workers. Le document sur les ensembles de règles indique de même que le moteur d'évaluation ne modifie pas directement l'état GitHub et ne contourne pas les contrôles de révision ou de fusion. La description du schéma qualifie la décision de simulation et de consultative. Même une recommandation de préparation entièrement étayée serait donc une raison pour un humain habilité d'examiner et de décider, pas une instruction conférant au moteur des droits de fusion.

L'examen des preuves traite les déclarations erronées de préparation ; un responsable de décision explicite empêche un avis de devenir une fusion non autorisée. Le texte produit devrait préserver cette distinction : « recommandé pour révision humaine » ne signifie pas « approuvé pour fusion ».

### Exercice 4 — Choisir un avis défendable

Pour le scénario synthétique PR-EXAMPLE, rédigez une phrase consultative défendable et nommez deux enregistrements manquants. Un agent consultatif peut-il fusionner automatiquement après leur arrivée ?

> **Réponse :** « Suspendre la recommandation de préparation pendant la vérification du résultat CI du head actuel, de l'approbation de révision et du résultat de politique. » Deux enregistrements manquants sont une exécution CI requise et terminée liée au SHA de head actuel et une approbation de révision pour cette révision ; le résultat de politique doit aussi être établi. Non. Le document consultatif interdit la fusion automatique dans le MVP et réserve la décision finale de fusion à un humain.

## 5. Rendre l'affirmation réfutable

L'affirmation limitée testée ici est : **à la révision figée, la validation du schéma seule n'impose pas l'exigence de preuve précise du document consultatif.** La fixture valide à preuves vides en est un contre-exemple direct. L'affirmation serait fausse si le schéma figé rejetait cette fixture parce qu'il exigeait une référence non vide et propre à une source. Il ne le fait pas. De futures révisions pourraient renforcer le schéma, tandis qu'un évaluateur en exécution pourrait imposer des contraintes supplémentaires. Aucune de ces possibilités ne change le résultat concernant cet artefact figé.

Une étude de terrain pourrait tester la qualité *réelle* des recommandations. Définissez une période et recensez les décisions de préparation des PR GA. Conservez chaque décision, le SHA de head cible, l'heure d'évaluation, les identifiants cités et les preuves correspondantes de CI, révision et politique. Comptez les références non résolues ou ne correspondant pas à la cible ; consignez l'ambiguïté séparément. Une seule recommandation sans fondement réfuterait l'affirmation selon laquelle *toutes* les recommandations de cette période étaient étayées. Aucune décision opérationnelle n'a été analysée ici.

### Exercice 5 — Énoncer un test et ses limites

Donnez un critère de réfutation pour l'affirmation limitée de cette leçon sur le schéma, puis une observation qui réfuterait l'affirmation hypothétique plus forte « toutes les recommandations de préparation à la fusion GA dans une période déclarée ont des preuves correspondantes à leur cible ». Cette leçon établit-elle cette affirmation plus forte ?

> **Réponse :** L'affirmation limitée serait fausse si le schéma figé rejetait la fixture synthétique complète uniquement parce que `evidence_refs` était vide ou dépourvu d'identifiant de source précis ; au contraire, il la valide. Une véritable recommandation dans la période déclarée avec une citation non résolue ou un résultat CI pour un autre SHA de head réfuterait l'affirmation universelle plus forte. Cette leçon ne dispose d'aucun corpus de décisions opérationnelles et n'établit rien sur la fréquence de tels cas.

## Limites et fondement de la recherche

Cette leçon compare trois artefacts Demerzel figés et valide un objet JSON synthétique contre leur schéma. Elle ne démontre ni quel document fait autorité pour une implémentation, ni que le moteur de politique a été exécuté, ni que des PR GA ont été évaluées, ni qu'un humain a accepté une recommandation. Le document et le schéma peuvent refléter des étapes de conception différentes ; leur divergence est visible, mais sa cause n'est pas établie ici. Une future révision du cours devrait vérifier le contrat alors en vigueur, suivre de véritables références de preuves et demander aux responsables du contrat comment le vocabulaire est mis en correspondance avant de faire des affirmations opérationnelles. Révision humaine du contenu, essais par des apprenants, révision linguistique humaine de ce brouillon français, synchronisation Learn et relecture publique restent en attente.
