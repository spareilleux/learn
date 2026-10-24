---
module_id: phi-006-preserve-the-quantifier-in-a-fold-verdict
department: philosophy
course: "Préserver le quantificateur dans un verdict de pliage"
level: intermediate
prerequisites: ["phi-002-when-is-an-advisory-decision-justified", "phy-010-check-local-flat-fold-angles", "cs-009-composing-origami-panel-constraints"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Préserver le quantificateur dans un verdict de pliage

> **Portée du brouillon.** Interprétation de théorèmes à partir de sources primaires, inspection du code à une révision précise et contre-exemples conçus pour le cours. Les revues humaines technique, linguistique et pédagogique ainsi que la vérification du HTML du cours déployé restent à effectuer. Aucune analyse IX complète, aucun pliage physique, export de maillage ou essai de scène [Godot](https://docs.godotengine.org/en/4.6/) n'ont été exécutés.

## La question du projet

Un agent affirme : « le sommet se plie à plat ». Affirme-t-il qu'une affectation existe, que l'affectation fournie convient ou qu'un objet entier a été validé ? Ces affirmations ont des sujets et des quantificateurs différents. Un message agentique de haut niveau devrait préserver cette distinction lorsqu'il condense les détails d'une API en une conclusion.

[PHY-010](../../physics/en/phy-010-check-local-flat-fold-angles.md) fournit un voisinage pédagogique : des secteurs de 60, 90, 120 et 90 degrés dans l'ordre des plis de e0 à e3. [CS-009](../../computer-science/en/cs-009-composing-origami-panel-constraints.md) distingue déjà les vérifications locales de recouvrement de l'ordre global des panneaux rigides. Ce cours se concentre sur une étape logique préalable : ce qu'un théorème ou une vérification limitée nous autorise réellement à affirmer.

## 1. Lire l'existence comme une existence

La [synthèse primaire de Demaine](https://erikdemaine.org/papers/OSME2001/paper.pdf#page=6) énonce la caractérisation angulaire du sommet unique sans directions de plis spécifiées. Sous ses hypothèses idéales, un degré pair et la condition angulaire de Kawasaki établissent qu'il existe une affectation montagne/vallée admettant un état local plié à plat. Ils ne disent pas que toutes les affectations conviennent.

Pour cette géométrie pédagogique, la somme alternée vaut `60-90+120-90=0`. Réussir ce test répond à une question d'existence sans affectation selon les hypothèses du théorème. Un destinataire ne doit pas insérer silencieusement une affectation particulière et lui attacher la même conclusion. Préservez dans l'énoncé l'épaisseur nulle, le voisinage intérieur unique, les plis utilisés et l'absence de directions prescrites.

### Exercice 1 : rétablir le quantificateur manquant

Un agent lit la réussite du test angulaire et écrit : « toutes les affectations M/V de ces quatre plis se plient à plat ». Reformulez la conclusion autorisée par le théorème. Quelle affirmation supplémentaire l'agent a-t-il insérée ?

> **Réponse:** Sous les hypothèses déclarées d'un sommet idéal unique sans affectation, il existe une affectation M/V admettant un pliage local à plat. L'agent a remplacé l'existence par une affirmation universelle sur toutes les affectations. La seule condition angulaire n'autorise ni ce remplacement ni une affirmation sur une feuille entière ou un objet épais.

## 2. Ne pas transformer des conditions nécessaires en certificat

L'[utilitaire local d'IX à la révision fixée](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/local.rs) calcule les angles alternés et le nombre de montagnes moins celui des vallées. Pour l'étiquetage `MMMV`, le résidu angulaire est nul et `M-V=2`.

Pourtant, les deux montagnes e0 et e1 délimitent le minimum strict de 60 degrés, dont les secteurs voisins font tous deux 90 degrés. Elles violent la restriction supplémentaire d'étiquettes opposées décrite dans l'[argument du plus petit angle de Hull](https://arxiv.org/pdf/1307.1065#page=8). Cela fournit un contre-exemple au caractère suffisant de ces deux conditions numériques pour une affectation prescrite. Cela ne réfute pas le théorème angulaire sans affectation : son témoin existentiel peut être une autre affectation.

### Exercice 2 : distinguer deux propositions

Pourquoi la géométrie peut-elle admettre une affectation à plat alors que `MMMV` est rejeté par une règle nécessaire supplémentaire ? Cette contradiction montre-t-elle que le théorème de Kawasaki a échoué ?

> **Réponse:** L'existence d'une affectation et la validité de cette affectation particulière sont deux propositions différentes. La géométrie pédagogique satisfait la condition angulaire sans affectation ; `MMMV` viole la restriction d'étiquettes du plus petit angle strict malgré la réussite des deux filtres numériques. Il n'y a ni contradiction ni réfutation du théorème d'existence.

## 3. Présenter honnêtement un domaine vérifié vide

La [logique d'applicabilité d'IX](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/local.rs#L106-L143) exclut de ces vérifications de théorèmes locaux les sommets de bord, isolés et comportant d'autres types de plis. La [spécification FOLD à la révision fixée](https://raw.githubusercontent.com/edemaine/fold/824f9fa6f944248787b0b2077ef622761489201e/doc/spec.md) donne à l'inconnu `U` son propre sens ; ce n'est pas un choix M/V réussi.

Dans la [fiche pédagogique d'applicabilité](../../../../code/streeling/evidence/origami-local-2026-10-22/applicability-cards.json), remplacer un pli du centre par `U` laisse 0 sommet applicable. Les listes d'échecs sont vides et le résidu maximal vaut 0. « Aucun sommet vérifié n'a échoué » peut être vrai sans aucun sommet vérifié. Cela n'implique pas qu'au moins un sommet a été vérifié, que des choix inconnus ont été résolus ou que le domaine complet visé a réussi.

### Exercice 3 : révéler une couverture vide

Un résumé conserve les listes d'échecs vides et le maximum de 0, mais supprime `applicable=0`. Quelle déduction erronée le destinataire peut-il faire ? Rédigez un énoncé de remplacement précis.

> **Réponse:** Le destinataire peut confondre l'absence d'échecs avec une couverture effective. Un énoncé précis serait : l'ensemble local vérifié est vide parce que le centre possède un pli incident inconnu ; aucun échec n'a été signalé dans cet ensemble vide. La fiche pédagogique est un modèle des branches du code, et non une exécution de l'analyseur complet ou une affectation résolue.

## 4. Distinguer l'analyseur entier d'un utilitaire

Le [prédicat agrégé d'IX](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/layers.rs#L879-L889) combine les échecs locaux avec des vérifications d'isométrie, d'orientation des plis, d'ordre et d'autres contrôles. Notre contre-exemple n'a pas été fourni sous forme d'un motif complet de plis accompagné d'un repère plié et d'un ordre des couches. Nous n'avons donc pas observé ce que cet analyseur entier renverrait pour un objet complété.

De même, un résultat local de pliage à plat ne fournit ni un état sans intersection d'une feuille entière, ni un empilement rigide d'épaisseur positive, ni une trajectoire de mouvement. L'[énoncé de portée de la bibliothèque](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/lib.rs#L1-L46) décrit des vérifications d'un état plié déclaré et une lecture distincte de l'épaisseur. La leçon pertinente est de préserver le domaine et le témoin de l'affirmation ; aucune affirmation actuelle sur la complexité ou la fabrication physique n'est nécessaire.

### Exercice 4 : borner l'affirmation sur l'implémentation

Un agent annonce : « IX accepte un origami impossible », parce que `MMMV` satisfait les deux formules locales. Quelles preuves manquent ? Énoncez ce que ce dossier établit réellement au sujet de l'utilitaire.

> **Réponse:** Il manque une entrée complète liée au code source, un repère plié et un ordre, ainsi qu'un résultat réel d'analyse complète. Ce dossier établit que les deux conditions numériques locales sont insuffisantes pour l'affectation prescrite, avec un contre-exemple fondé sur une règle nécessaire supplémentaire. Il n'établit ni l'acceptation par l'analyseur entier, ni l'impossibilité physique sous d'autres modèles, ni un bogue de production reproduit.

## 5. Composer des conclusions à un niveau supérieur

Une transmission utile proposée indique le sujet, l'identité de l'entrée, le prédicat, le domaine vérifié, les hypothèses et le témoin disponible. Pour le résultat angulaire, le sujet est un voisinage idéal de sommet unique sans affectation et la conclusion est existentielle. Pour une affectation fournie, indiquez quels filtres nécessaires ont été vérifiés et lesquels restent absents. Pour une couverture vide, conservez la raison de l'exclusion.

Ces distinctions peuvent figurer dans un rapport typé ; un nouveau DSL reste un candidat tant qu'il n'a pas réduit les erreurs réelles en aval par rapport à cette solution plus simple. Un moteur de rendu peut afficher un candidat alors qu'un solveur ne dispose toujours pas de son témoin plié. Les [fiches d'affirmations logiques](../../../../code/streeling/evidence/origami-local-2026-10-22/logical-claims.json) sont des exemples pédagogiques, et non un schéma normatif ou un pont vers une scène implémenté.

### Exercice 5 : rédiger la transmission sémantique

Remplacez « origami validé, prêt pour Godot » dans l'exemple `MMMV` par un message qui préserve l'affectation, les résultats numériques, la restriction supplémentaire et les résultats manquants. Rédiger ce message implémente-t-il le DSL proposé ?

> **Réponse:** L'affectation pédagogique `MMMV` sur les secteurs de 60, 90, 120 et 90 satisfait la condition angulaire de Kawasaki et le décompte de Maekawa, mais viole la règle d'étiquettes opposées du plus petit angle strict. Aucun témoin complet d'état plié, résultat IX complet, pliage physique ou import Godot n'ont été observés. Ce message préserve la portée de la conclusion ; il n'implémente ni ne valide un nouveau DSL.
