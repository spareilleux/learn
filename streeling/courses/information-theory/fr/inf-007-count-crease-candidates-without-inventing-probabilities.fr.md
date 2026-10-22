---
module_id: inf-007-count-crease-candidates-without-inventing-probabilities
department: information-theory
course: "Compter les affectations candidates des plis sans inventer de probabilités"
level: intermediate
prerequisites: ["inf-001-entropy-of-governance", "phy-010-check-local-flat-fold-angles"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Compter les affectations candidates des plis sans inventer de probabilités

> **Portée du brouillon.** Affectations étiquetées exhaustives et modèles de probabilité explicites conçus pour le cours, avec inspection du code à une révision précise. Les revues humaines technique, linguistique et pédagogique ainsi que la vérification du HTML du cours déployé restent à effectuer. Aucun taux de réussite d'agent, aucune résolution complète d'origami, exécution Rust ou exportation de scène n'ont été mesurés.

## La question du projet

Un agent de recherche créative annonce qu'une contrainte a éliminé la moitié de ses candidats. Quelle incertitude cela a-t-il éliminée, et que signifie un candidat restant ? Utilisez le voisinage de degré quatre de [PHY-010](../../physics/en/phy-010-check-local-flat-fold-angles.md) : les secteurs cycliques sont de 60, 90, 120 et 90 degrés, avec les plis étiquetés de e0 à e3. La condition angulaire géométrique est fixée et satisfaite ; seules les étiquettes montagne/vallée varient.

L'[utilitaire local d'IX à la révision fixée](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/local.rs) implémente des filtres d'angles et de décompte, mais pas la règle supplémentaire du plus petit angle utilisée dans ce calcul pédagogique. Le [relevé d'énumération](../../../../code/streeling/evidence/origami-local-2026-10-22/assignment-enumeration.json) énumère tous les candidats et les deux prédicats séparément. Ce n'est pas la sortie d'un solveur complet.

## 1. Compter les choix étiquetés avant le filtrage

Chacun des quatre plis possède deux choix binaires, donnant `2^4=16` chaînes étiquetées. Conservez l'identité des plis : permuter les étiquettes peut changer leur présence aux bords du plus petit angle. Nous ne passons pas au quotient par symétrie et n'identifions pas une chaîne à son inversion montagne/vallée.

Choisissez maintenant explicitement une distribution uniforme pédagogique sur ces chaînes. Chacune a une probabilité de `1/16` ; l'entropie de Shannon est de 4 bits. La [définition primaire de l'entropie](https://people.math.harvard.edu/~ctm/home/text/others/shannon/entropy/entropy.pdf#page=11) utilise l'opposé d'une somme logarithmique pondérée par les probabilités. En base 2, `H(X)=-sum(p_i*log2(p_i))` ; un ensemble uniforme de N choix donne `log2(N)`. Compter les possibilités ne suffit pas à établir la distribution réelle d'un agent ou d'un processus physique.

### Exercice 1 : déclarer l'ensemble probabiliste

Combien d'affectations étiquetées existent, et quelle entropie découle de la loi a priori uniforme pédagogique ? Ce seul décompte prouverait-il qu'un agent réel échantillonne chaque chaîne aussi souvent ?

> **Réponse:** Il existe 16 affectations, avec une probabilité de `1/16` chacune et une entropie de 4 bits selon la loi a priori déclarée. Le décompte n'établit pas une distribution d'échantillonnage réelle ; l'égalité des probabilités est une hypothèse pédagogique explicite.

## 2. Conditionner sur les filtres déclarés

La condition de décompte de Maekawa conserve les affectations avec trois montagnes et une vallée, ou l'inverse. Il y en a `4+4=8`. Conditionner la loi a priori uniforme sur cet événement donne une probabilité de `1/8` par chaîne restante et une entropie de 3 bits.

Le minimum strict de 60 degrés se trouve entre e0 et e1. Appliquer la règle nécessaire supplémentaire des étiquettes opposées conserve quatre candidats ayant passé le décompte : `MVMM`, `MVVV`, `VMMM` et `VMVV`. Sous condition de réussite aux deux tests, chacun a une probabilité de `1/4` et l'entropie est de 2 bits. C'est une réduction le long de la branche acceptée. Un candidat restant a passé les filtres nommés ; ce n'est ni un état plié exporté, ni une réussite physique mesurée, ni une preuve de faisabilité globale.

### Exercice 2 : compter les deux réductions

Donnez le décompte et l'entropie uniforme conditionnelle après le filtre de décompte et après les deux filtres. Pourquoi serait-il faux de qualifier les huit premiers candidats de « huit pliages vérifiés » ?

> **Réponse:** Le filtre de décompte laisse 8 candidats et 3 bits ; les deux filtres laissent 4 candidats et 2 bits. Le premier ensemble comprend des affectations comme `MMMV` qui violent la restriction supplémentaire du plus petit angle. Aucune étape de filtrage ne fournit un témoin complet d'état plié ou une observation physique ; huit candidats ayant passé le décompte ne sont donc pas huit pliages vérifiés.

## 3. Séparer la cardinalité de l'entropie

Pour les quatre mêmes identités de candidats finaux, choisissez une autre distribution pédagogique : les probabilités `1/2`, `1/4`, `1/8` et `1/8` dans l'ordre indiqué. Son entropie est de 1.75 bits, tandis que la distribution uniforme sur les mêmes identités a 2 bits. Le nombre d'états n'a pas changé.

Le [relevé d'information fixé](../../../../code/streeling/evidence/origami-local-2026-10-22/candidate-information.json) conserve les deux distributions. Sans preuves sur les probabilités, `log2(N)` est l'entropie maximale sur N possibilités, et non une entropie observée. Réciproquement, une faible entropie ne certifie pas que le candidat probable est correct ou fabricable.

### Exercice 3 : calculer une distribution non uniforme

Calculez l'entropie pour les probabilités `1/2`, `1/4`, `1/8` et `1/8`. Quelle est la borne supérieure fondée sur la cardinalité ? L'écart mesure-t-il une amélioration de la qualité du pliage ?

> **Réponse:** Les contributions sont de `0.5+0.5+0.375+0.375=1.75` bits. La borne supérieure pour quatre états est de 2 bits. L'écart reflète cette concentration de probabilité pédagogique, et non une meilleure qualité de pliage, un étalonnage observé de l'agent ou un résultat physique.

## 4. Distinguer une branche sélectionnée de la moyenne

Le classificateur pédagogique déterministe émet l'une de trois étiquettes. Huit chaînes échouent à la règle de décompte ; quatre passent le décompte mais échouent à la règle du plus petit angle ; quatre passent les deux. Selon la loi a priori uniforme, les probabilités de ces étiquettes sont `1/2`, `1/4` et `1/4`.

L'entropie moyenne restante des affectations après avoir appris cette étiquette grossière est de `0.5*3+0.25*2+0.25*2=2.5` bits. L'étiquette elle-même porte 1.5 bits, et `4=1.5+2.5`. Sélectionner seulement la branche acceptée laisse 2 bits, mais cette branche n'est pas la moyenne sur toutes les entrées. Annoncer une réduction moyenne de 2 bits en regardant seulement les entrées acceptées changerait silencieusement le conditionnement.

### Exercice 4 : inclure les branches rejetées

Calculez l'espérance de l'entropie restante avec les tailles et probabilités des trois catégories. Quelle est l'information moyenne de l'étiquette grossière ? Pourquoi les 2 bits restants de la branche acceptée constituent-ils une autre statistique ?

> **Réponse:** L'espérance restante est de 2.5 bits ; l'étiquette porte donc en moyenne `4-2.5=1.5` bits. Les 2 bits restants de la branche acceptée sont conditionnés par cet événement particulier, dont la probabilité a priori est `1/4` ; ce n'est pas la moyenne pondérée des branches rejetées et acceptées.

## 5. Préserver les identités et le sens des prédicats dans une transmission

Une étiquette grossière de réussite ne permet pas de reconstruire l'affectation qui a réussi. Dans l'ensemble des huit candidats ayant passé le décompte, une description uniforme conditionnelle possède encore 3 bits d'incertitude sur l'affectation. Un agent qui doit placer des plis particuliers doit conserver l'étiquetage réel et la géométrie, au lieu de recevoir seulement « vérifications locales réussies ». L'inconnu `U` dans la [spécification FOLD à la révision fixée](https://raw.githubusercontent.com/edemaine/fold/824f9fa6f944248787b0b2077ef622761489201e/doc/spec.md) est une autre catégorie d'entrée ; il ne signifie pas automatiquement un tirage binaire équiprobable entre M et V.

Une transmission de haut niveau proposée peut indiquer les identités des candidats, l'ordre des coordonnées, les prédicats testés, les domaines ignorés et un modèle de probabilité explicite lorsqu'il existe. C'est une tâche de préservation de l'information, et non une obligation de construire un nouveau langage. Un simple rapport typé peut suffire. Mesurez les erreurs réelles de sélection ou le coût de recherche avant d'affirmer qu'un DSL ou un ensemble de candidats plus petit a amélioré le processus agentique.

### Exercice 5 : corriger un résumé pauvre en information

Un agent envoie seulement « décompte réussi ; huit possibilités ; 3 bits », alors que le destinataire doit sélectionner un motif de plis étiqueté précis. Qu'est-ce qui a été perdu, et quelle hypothèse donne les 3 bits ? Une étiquette d'entrée inconnue peut-elle être automatiquement traitée comme ce même modèle de probabilité ?

> **Réponse:** L'affectation particulière et sa relation avec les identifiants géométriques des plis ont été perdues. Trois bits décrivent l'ensemble uniforme conditionnel des huit candidats ayant passé le décompte, et non une distribution observée. Une étiquette inconnue ne fournit ni loi de probabilité a priori ni affectation complète. Transmettez les identités et la portée des prédicats, et précisez le modèle de probabilité ou laissez-le inconnu ; les résultats du pliage complet et de la scène restent non observés.
