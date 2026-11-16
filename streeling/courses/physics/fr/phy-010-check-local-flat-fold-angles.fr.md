---
module_id: phy-010-check-local-flat-fold-angles
department: physics
course: "Vérifier les angles locaux d'un pliage à plat"
level: intermediate
prerequisites: ["phy-005-sheet-thickness-and-scene-units", "cs-009-composing-origami-panel-constraints"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Vérifier les angles locaux d'un pliage à plat

> **Portée du brouillon.** Code public d'IX à une révision précise, lecture de sources primaires sur les théorèmes et calculs d'angles et d'affectations conçus pour le cours. Les revues humaines technique, linguistique et pédagogique ainsi que la vérification du HTML du cours déployé restent à effectuer. Aucun analyseur Rust, papier physique ou scène hôte n'ont été utilisés, et aucun maillage plié n'a été produit pour ce cours.

## La question du projet

Avant qu'un agent de création transmette un motif de plis à une scène, quelles vérifications angulaires sont utiles ? [CS-009](../../computer-science/en/cs-009-composing-origami-panel-constraints.md) traite déjà les contraintes globales d'ordre des panneaux. Ici, nous examinons un autre objet : un petit voisinage d'un sommet intérieur unique sur un matériau plat idéal d'épaisseur nulle, où tous les plis énumérés sont utilisés dans un pliage à plat. Le [module local d'IX à la révision fixée](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/local.rs) fournit des filtres numériques concrets. Toutes les observations du code du projet utilisent la révision d'IX `d7c22fdd6a62becb66b9d7246ea85850e7c55854`.

## 1. Retrouver l'ordre cyclique des secteurs

Utilisez quatre demi-droites sortantes étiquetées depuis un sommet central. Leurs directions sont mesurées dans le sens antihoraire depuis un axe déclaré :

| Demi-droite | Direction, degrés | Secteur jusqu'à la demi-droite suivante, degrés |
| --- | --- | --- |
| e0 | 0 | 60 |
| e1 | 60 | 90 |
| e2 | 150 | 120 |
| e3 | 270 | 90 |

Le dernier secteur revient à la première demi-droite. IX [trie les directions géométriques](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/local.rs#L45-L71) à partir de `atan2` et utilise un reste positif sur un tour complet. L'ordre de la liste d'arêtes d'entrée ne suffit pas à définir les secteurs voisins. Le [relevé angulaire fixé](../../../../code/streeling/evidence/origami-local-2026-10-22/sector-calculations.json) vérifie les 24 permutations des quatre demi-droites d'entrée ; ces permutations préservent la même géométrie.

### Exercice 1 : fermer le circuit angulaire

Retrouvez les quatre secteurs à partir des directions des demi-droites, y compris le retour au point de départ. Quel est leur total ? Calculer les différences dans un ordre arbitraire de liste d'arêtes préserverait-il ce voisinage ?

> **Réponse:** Les secteurs sont de 60, 90, 120 et 90 degrés, pour un total de 360. Les voisins dans une liste arbitraire ne sont pas nécessairement des voisins géométriques ; triez autour du sommet et incluez le retour au point de départ avant d'appliquer le test des secteurs.

## 2. Appliquer Kawasaki avec ses hypothèses

Pour un sommet intérieur idéal unique sans affectation des plis, la condition de Kawasaki exige un degré pair et une somme alternée nulle des secteurs consécutifs. Sur un matériau plat, cela équivaut à une somme de 180 degrés pour chacun des deux groupes alternés. La [synthèse de Demaine, section 3.1](https://erikdemaine.org/papers/OSME2001/paper.pdf#page=6), laisse explicitement les directions montagne/vallée non spécifiées dans cet énoncé d'existence.

Nos secteurs donnent `60-90+120-90=0`, avec des totaux alternés de 180 et 180. Changer cycliquement la demi-droite de départ peut inverser le signe d'un résidu non nul ; sa valeur absolue reste inchangée pour un degré pair. Un sommet de bord ou un sommet contenant un pli plat inutilisé ne satisfait pas automatiquement ces hypothèses. La réussite du test angulaire n'établit pas non plus une affectation particulière ou un mouvement physique de panneaux épais.

### Exercice 2 : énoncer la conclusion angulaire

Calculez les totaux alternés du sommet pédagogique. Qu'établit le théorème du sommet unique sans affectation, sous ses hypothèses ? Établit-il la validité de tous les étiquetages montagne/vallée possibles ?

> **Réponse:** Les totaux sont `60+120=180` et `90+90=180`. Sous les hypothèses déclarées du sommet idéal unique, il existe une affectation montagne/vallée admettant un pliage local à plat. C'est une affirmation d'existence, et non l'affirmation que toutes les affectations conviennent ou qu'une feuille entière ou un objet épais sont validés.

## 3. Garder la tolérance en radians

La fonction de bas niveau d'IX accepte une tolérance en radians ; l'[appel agrégé](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/layers.rs#L879-L889) utilise `1e-9`. Son prédicat angulaire échoue lorsque le degré est impair ou que la valeur absolue du résidu dépasse cette tolérance.

Perturbez la demi-droite e1 de delta radians positifs en gardant les autres directions fixes. Les deux secteurs voisins changent de plus delta et de moins delta ; la valeur absolue du résidu alterné devient donc `2*abs(delta)` en arithmétique exacte. Un delta de `1e-10` donne `2e-10`, dans la tolérance ; un delta de `1e-8` donne `2e-8`, hors tolérance. La transcription enregistrée utilise des opérations angulaires ordinaires en virgule flottante ; conservez donc son résidu calculé au lieu de présenter l'expression idéale comme un résultat de Rust exécuté. Cette tolérance numérique n'est pas une marge mesurée de pliage du papier ou de fabrication.

### Exercice 3 : comparer les perturbations

Appliquez la tolérance de `1e-9` radians aux deux deltas de `1e-10` et `1e-8` radians. Quels cas numériques réussissent ? Peut-on lire directement la tolérance comme des degrés ou une spécification d'atelier ?

> **Réponse:** Les résidus valent environ `2e-10` et `2e-8` radians ; le premier réussit donc et le second échoue selon la règle numérique déclarée. On ne peut pas rebaptiser silencieusement les radians en degrés, et aucune mesure de matériau ou de procédé ne justifie ici une tolérance d'atelier.

## 4. Vérifier les étiquettes autant que les angles

Pour une affectation montagne/vallée prescrite, Maekawa exige `abs(M-V)=2`. Avec quatre plis, cela permet trois plis d'un type et un de l'autre. Cela ne contraint pas l'emplacement de l'étiquette minoritaire. La [synthèse primaire de Hull](https://arxiv.org/pdf/1307.1065#page=8) donne d'autres restrictions d'affectation, dont la construction du plus petit angle avec ses hypothèses sur les angles voisins.

Ici, le secteur de 60 degrés entre e0 et e1 est strictement plus petit que ses deux voisins de 90 degrés. Les plis qui le délimitent doivent avoir des types montagne/vallée opposés dans une affectation idéale valide à plat. L'étiquetage pédagogique `MMMV`, dans l'ordre des demi-droites de e0 à e3, a `M-V=2` et satisfait la condition angulaire. Pourtant, e0 et e1 sont tous deux des montagnes, ce qui viole cette restriction nécessaire supplémentaire. Ces deux filtres numériques seuls ne certifient donc pas cette affectation prescrite.

### Exercice 4 : rejeter le raccourci de la condition suffisante

Pour `MMMV`, calculez la différence entre montagnes et vallées et identifiez la règle supplémentaire violée. Cela montre-t-il que la géométrie angulaire elle-même n'admet aucune affectation ? L'analyseur IX complet a-t-il accepté cet objet ici ?

> **Réponse:** Trois montagnes moins une vallée donnent 2, mais les plis qui délimitent le minimum strict de 60 degrés sont tous deux des montagnes. Cette affectation prescrite viole la règle supplémentaire ; la géométrie angulaire peut encore admettre une autre affectation valide selon le théorème du sommet unique. Aucun objet IX complet ni aucune exécution de l'analyseur n'ont été fournis ; aucune acceptation par l'analyseur complet n'est donc revendiquée.

## 5. Préserver le domaine testé

L'[enveloppe locale d'applicabilité](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/local.rs#L106-L143) ne comprend que les sommets intérieurs dont tous les plis incidents sont des montagnes ou des vallées. La [spécification FOLD à la révision fixée](https://raw.githubusercontent.com/edemaine/fold/824f9fa6f944248787b0b2077ef622761489201e/doc/spec.md) distingue les plis inconnus `U`, plats `F` et de bord `B` de ces plis affectés. Un inconnu ne devient pas silencieusement une montagne ou une vallée.

Notre fiche d'incidence comporte un centre, quatre sommets extérieurs sur un anneau de bord et un sommet isolé. Avec les plis du centre affectés, ses décomptes modélisés sont de 1 applicable, 4 ignorés comme sommets de bord et 1 ignoré comme sommet isolé. Remplacer un pli du centre par `U` donne 0 applicable et 1 ignoré pour un autre type de pli, tandis que les échecs restent vides et que le résidu maximal est initialisé à 0. Ce sont des décomptes de branches du code conçus pour le cours, et non un fichier FOLD complet exécuté ou analysé. [PHI-006](../../philosophy/en/phi-006-preserve-the-quantifier-in-a-fold-verdict.md) explique la différence logique entre l'absence d'échecs et une affectation testée.

### Exercice 5 : lire un ensemble vérifié vide

Dans la fiche avec un pli inconnu, qu'est devenue la couverture du centre ? Des échecs vides et un résidu maximal de 0 prouvent-ils qu'il a été vérifié et a réussi ? Que doit conserver un agent en aval ?

> **Réponse:** Le centre est ignoré à cause du pli incident inconnu, laissant 0 sommet applicable. Les échecs vides et le maximum de 0 décrivent un ensemble vérifié vide ; ils n'établissent pas une affectation complète testée. Conservez l'applicabilité et les décomptes de sommets ignorés, les étiquettes d'affectation d'origine, l'identité du code source, la tolérance et la portée locale du prédicat. Le pliage physique et le transfert vers une scène restent non observés.
