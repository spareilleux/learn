---
module_id: phy-012-rotate-directional-stiffness-with-the-material
department: physics
course: "Faire tourner la rigidité directionnelle avec le matériau"
level: intermediate
prerequisites: ["phy-006-check-weave-scene-units", "phy-008-keep-surface-normals-perpendicular"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Faire tourner la rigidité directionnelle avec le matériau

> **Portée du brouillon.** Calculs pédagogiques de ressort linéaire et lecture du code à une révision précise. Les revues humaines technique, artisanale, linguistique et par de véritables apprenants restent à effectuer. Aucune éprouvette de matériau, simulation Godot ou test IX n'ont été exécutés. La disponibilité du code public et le HTML du cours déployé font l'objet de vérifications de publication distinctes.

## La question du projet

Faire tourner un objet d'apparence tissée dans l'observatoire permet-il de déterminer sa résistance à une charge ? [PHY-006](phy-006-check-weave-scene-units.md) établit les longueurs et les unités de scène ; [PHY-008](phy-008-keep-surface-normals-perpendicular.md) établit les transformations des normales. Aucun ne fournit une loi de réponse du matériau. Ce cours ajoute un modèle pédagogique de ressort à deux degrés de liberté, et non un tenseur de tissu continu ou une simulation textile étalonnée.

La [transcription du cours du MIT sur les ressorts linéaires](https://ocw.mit.edu/courses/res-2-002-finite-element-procedures-for-solids-and-structures-spring-2010/5195e8fac694f612c5bac7515b05f6ef_oNqSzzycRhw.pdf) donne l'équilibre de rigidité et l'énergie quadratique de déformation. Son texte a été lu ; la vidéo du cours et les figures du PDF n'ont pas été examinées. Nous utilisons ces relations linéaires avec des nombres posés.

## 1. Déclarer la réponse et ses unités

Notons le déplacement local `u` en mm, la force `f` en N et la rigidité `K_local=[[4,0],[0,1]]` en N/mm. Définissez `f=K*u` et l'énergie stockée `E=0.5*u^T*K*u` en N*mm. Les deux coordonnées décrivent une réponse idéale de ressort linéaire autour d'un équilibre. Ce sont des axes plans abstraits, sans correspondance prescrite avec les angles d'Euler de Godot ou la hauteur dans le monde.

### Exercice 1 : comparer les axes locaux

Trouvez la force et l'énergie pour les déplacements locaux `[1,0]` et `[0,1]`. Qu'établit la différence au sujet d'un véritable échantillon tissé ?

> **Réponse:** Les forces sont `[4,0]` N et `[0,1]` N ; les énergies sont 2 et 0.5 N*mm. Le modèle dépend de la direction parce que ses rigidités posées diffèrent. Ces calculs n'établissent aucune propriété mesurée d'un textile physique.

## 2. Faire tourner la réponse du matériau, et pas seulement la silhouette

Pour une rotation mathématique active, définissez `R=[[cos(theta),-sin(theta)],[sin(theta),cos(theta)]]`. Les grandeurs transformées sont `u_world=R*u_local`, `K_world=R*K_local*R^T` et `f_world=R*f_local`. La transposée est ici l'inverse parce que la rotation est orthogonale.

Après un quart de tour, `K_world=[[1,0],[0,4]]`. Une géométrie identique peut donc accompagner des réponses différentes à la même force dans le repère du monde. Sous la force `[1,0]` N, le modèle non tourné a un déplacement de `[0.25,0]` mm, tandis que le matériau tourné d'un quart de tour a `[1,0]` mm. Un maillage dépourvu de sa loi de réponse et de son repère matériel ne permet pas d'identifier la réponse visée.

### Exercice 2 : garder la sollicitation fixe dans le repère du monde

Pour un déplacement `[1,0]` mm dans le repère du monde, comparez force et énergie avant et après le quart de tour. Expliquez ensuite l'exemple de déplacement à force fixe ci-dessus.

> **Réponse:** Avant rotation, la force est `[4,0]` N et l'énergie 2 N*mm ; après, elles sont `[1,0]` N et 0.5 N*mm. Pour la force fixe `[1,0]` N, résoudre les deux systèmes diagonaux donne plutôt `[0.25,0]` et `[1,0]` mm. Fixer une force et fixer un déplacement sont des expériences différentes ; aucune réponse ne découle de la géométrie seule.

## 3. Préserver les termes de couplage

À 45 degrés, `K_world=[[2.5,1.5],[1.5,2.5]]`. Un déplacement `[1,0]` mm dans le repère du monde produit la force `[2.5,1.5]` N et l'énergie 1.25 N*mm. La force transversale fait partie de la réponse tournée. Remplacer cette matrice par sa diagonale change le modèle.

### Exercice 3 : révéler une substitution limitée à la diagonale

Pour un déplacement `[1,-1]` mm dans le repère du monde à 45 degrés, calculez la force et l'énergie. Comparez l'énergie obtenue après suppression silencieuse des termes hors diagonale.

> **Réponse:** La matrice complète donne `[1,-1]` N et l'énergie 1 N*mm. Ne conserver que les termes diagonaux donne la force `[2.5,-2.5]` N et l'énergie 2.5 N*mm. Les termes supprimés portent le couplage ; leur omission n'est pas une rotation équivalente.

## 4. Distinguer la covariance des coordonnées d'une nouvelle expérience

Si le déplacement et la réponse tournent ensemble, l'énergie est inchangée : substituer les grandeurs transformées annule les facteurs adjacents de transposition et de rotation. La force tourne avec le déplacement. Cela diffère des sollicitations fixes dans le monde ci-dessus, où la direction du matériau change par rapport à un déplacement imposé inchangé.

Le [relevé pédagogique de réponse](../../../../code/streeling/evidence/weave-material-2026-10-22/directional-response.json) contient 36 cas de covariance sur 6 angles et 6 déplacements, ainsi que des sollicitations distinctes fixes dans le monde. Les résidus de virgule flottante sont conservés avec les exemples idéaux de quart de tour et d'angle diagonal. Ce sont des vérifications mathématiques, et non des observations du moteur natif. Les valeurs propres restent 1 et 4 N/mm ; l'énergie quadratique posée est donc positive pour tout déplacement non nul.

### Exercice 4 : nommer l'invariant

Pourquoi l'énergie peut-elle rester invariante sous une rotation des coordonnées et du matériau alors qu'un déplacement fixe dans le monde donne une autre énergie ? Une énergie quadratique positive valide-t-elle un modèle de tissu réel ?

> **Réponse:** La covariance fait tourner le déplacement avec la rigidité et décrit le même état relatif. Le test fixe dans le monde change leur direction relative. L'énergie positive découle des deux valeurs propres positives dans ce modèle linéaire idéal ; elle ne valide pas les comportements non linéaires, de glissement, de flambement ou irréversibles d'un tissu réel.

## 5. Lire les limites réelles de la scène et des API

La [scène pédagogique de Learn à la révision fixée](https://github.com/spareilleux/learn/blob/eebf49cb0b69a314bd13015340335a983aa64bfe/code/streeling/weave-godot/trial.gd) crée des boîtes séparées avec des matériaux colorés et des corps de collision statiques. L'[anisotropie de rendu de Godot](https://docs.godotengine.org/en/4.6/classes/class_basematerial3d.html#class-basematerial3d-property-anisotropy-enabled) modifie un reflet spéculaire dans l'espace tangent. [PhysicsMaterial](https://docs.godotengine.org/en/4.6/classes/class_physicsmaterial.html) décrit des propriétés de collision telles que le frottement et le rebond. [StaticBody3D](https://docs.godotengine.org/en/4.6/classes/class_staticbody3d.html) ne se déplace pas sous les forces ou contacts externes. Aucun de ces réglages sélectionnés n'implémente la loi de ressort ci-dessus.

L'[ADR d'IX sur l'épaisseur à la révision fixée](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/docs/adr/0007-origami-thickness-as-parallel-rigid-panels.md) définit une lecture géométrique en panneaux parallèles, et non une réponse de rigidité mesurée. Une disposition cyclique des couches peut satisfaire certaines règles de couches tout en refusant un empilement rigide parallèle d'épaisseur positive ; ce n'est pas une impossibilité universelle de fabrication.

### Exercice 5 : préparer un essai de matériau avec accès aux sources

Lisez la scène et les trois références Godot. Un agent propose de régler l'anisotropie de rendu et le frottement pour étalonner la rigidité de chaîne. Corrigez l'affirmation et précisez les preuves nécessaires à une future comparaison utile.

> **Réponse:** La forme du reflet et le frottement de collision ne fournissent pas cette loi de ressort directionnelle, et les corps statiques actuels ne peuvent pas démontrer une déformation sous charge. Conservez la géométrie de l'éprouvette, les directions matérielles, les unités, les conditions aux limites, les forces appliquées et les déplacements mesurés ; ajustez un modèle de réponse explicitement choisi et réservez des cas indépendants de charge et de direction pour le vérifier. Comparez une référence simple de ressort ajusté avant de proposer un solveur plus riche. Consignez l'incertitude, les cas d'échec et la revue artisanale. Aucun étalonnage, intégration de solveur ou essai physique n'ont eu lieu ici.
