---
module_id: cyb-008-check-convergence-before-repeating-a-correction
department: cybernetics
course: "Vérifier la convergence avant de répéter une correction"
level: intermediate
prerequisites: ["cyb-004-observe-before-correcting-a-feedback-loop", "phy-012-rotate-directional-stiffness-with-the-material"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Vérifier la convergence avant de répéter une correction

> **Périmètre du brouillon.** Itérations conçues en arithmétique exacte pour un équilibre linéaire posé par hypothèse. Aucun régulateur physique, étalonnage de matériau, solveur natif ou boucle d’agent n’a été exécuté. Les revues humaines techniques, artisanales, linguistiques par des personnes maîtrisant la langue et pédagogiques avec des apprenants restent à effectuer ; la vérification du HTML du cours déployé est distincte.

## La question du projet

Un agent de l’observatoire pourrait-il résoudre la réponse d’un matériau en corrigeant à répétition le résidu de force ? [PHY-012](../../physics/en/phy-012-rotate-directional-stiffness-with-the-material.md) fournit une loi de ressort conçue pour l’exercice, pas un modèle de tissu étalonné. [CYB-004](cyb-004-observe-before-correcting-a-feedback-loop.md) distingue une correction utile d’une exécution réussie. Nous déterminons ici quand une correction numérique précise converge et quand sa répétition amplifie son erreur.

Utilisons la rigidité locale `K=diag(4,1)` en N/mm, la force cible `F=[4,1]` N et le déplacement initial `u[0]=[0,0]` mm. L’équilibre exact est `u*=[1,1]` mm. Aucune convention de repère de l’environnement d’accueil n’est sous-entendue.

## 1. Définir le résidu et le gain

Le résidu est `F-K*u[n]`, en N. La mise à jour numérique est `u[n+1]=u[n]+alpha*(F-K*u[n])` ; `alpha` s’exprime donc en mm/N. Avec l’erreur `e[n]=u[n]-u*`, la substitution donne `e[n+1]=(I-alpha*K)*e[n]`.

Il s’agit d’une itération algébrique indexée par les mises à jour, pas d’une équation du mouvement en secondes. Elle ne comporte ni inertie, ni contact, ni bruit de mesure, ni limites des actionneurs. Ces omissions sont des hypothèses, pas une description validée d’une machine de fabrication artisanale.

### Exercice 1 : calculer les premières corrections

Fixez `alpha=0.25` mm/N. Calculez les deux premiers déplacements et les deux facteurs d’erreur. Pourquoi un gain sans dimension de même valeur numérique ne définit-il pas la même mise à jour ?

> **Réponse:** Les deux premiers déplacements sont `[1,0.25]` et `[1,0.4375]` mm. Les facteurs d’erreur sont `1-4*alpha=0` et `1-alpha=0.75`. Le produit du résidu de force par le gain doit donner un déplacement ; les unités mm/N du gain sont donc nécessaires. Changer les unités sans transformer le gain modifie le modèle numérique.

## 2. Déduire l’intervalle strict de convergence

Pour que toute erreur initiale converge vers zéro, les deux facteurs d’erreur doivent avoir une valeur absolue inférieure à un. Les conditions sont `abs(1-4*alpha)<1` et `abs(1-alpha)<1`, soit conjointement `0<alpha<0.5` mm/N. Les bornes sont exclues.

À `alpha=0.25`, l’erreur sur l’axe rigide disparaît après la première mise à jour ; l’autre se contracte d’un facteur 0.75 par mise à jour. À la mise à jour 8, le déplacement est `[1,0.8998870849609375]` mm. Le résidu sur le second axe vaut 0.1001129150390625 N. Une contraction géométrique par mise à jour ne démontre ni rapidité en temps réel écoulé ni amélioration d’un processus physique.

### Exercice 2 : démontrer la convergence sous les hypothèses énoncées

Déduisez l’intervalle à partir des deux modes propres. Expliquez pourquoi le résultat à la mise à jour 8 n’atteint pas encore l’équilibre exact et si l’observation de huit mises à jour achevées prouverait la convergence.

> **Réponse:** Le premier mode exige `0<alpha<0.5` ; le second exige `0<alpha<2`. Leur intersection est donc `0<alpha<0.5`. L’erreur lente à la mise à jour 8 est `-0.75^8` mm, et non zéro. Une trace finie ne suffit pas à constituer la preuve : la contraction découle de la récurrence linéaire exacte et de ses hypothèses. Aucune exécution native ni convergence physique n’a été observée.

## 3. Tester l’oscillation à la borne et la divergence

À `alpha=0.5`, le facteur d’erreur du mode rigide vaut -1. Avec notre condition initiale, le premier déplacement alterne entre 0 et 2 mm. Sa moyenne par paires est de 1 mm, mais la suite ne converge pas vers cette valeur. L’autre coordonnée converge.

À `alpha=0.6`, les facteurs valent -1.4 et 0.4. Une erreur non nulle du mode rigide croît en valeur absolue tout en alternant de signe. Mesurer seulement la seconde coordonnée, qui s’améliore, masquerait le mode instable.

Définissons l’écart de potentiel quadratique par `0.5*e^T*K*e` en N*mm. Au gain limite, sa contribution rigide reste égale à 2 N*mm. Un déplacement moyen correct ou une seule coordonnée dont l’erreur diminue ne constitue pas un critère d’arrêt suffisant.

### Exercice 3 : rejeter une mesure de réussite incomplète

Un agent calcule une moyenne de 1 mm pour la première coordonnée au gain limite et annonce une réussite. Analysez cette affirmation à l’aide de la suite des erreurs et de l’écart de potentiel. Que se passe-t-il au gain 0.6 ?

> **Réponse:** La moyenne masque l’erreur de déplacement alternée de valeur absolue 1 mm, laissant un écart de potentiel du mode rigide de 2 N*mm. Les itérés ne convergent pas. Au gain 0.6, une erreur rigide non nulle est au contraire multipliée par -1.4, et sa valeur absolue augmente. Examinez tous les modes pertinents et un critère de résidu ou d’erreur déclaré, pas seulement une moyenne ou la coordonnée stable.

## 4. Modifier le retard et déduire à nouveau le modèle

Utilisons maintenant délibérément le déplacement de la mise à jour précédente dans le résidu : `u[n+1]=u[n]+alpha*(F-K*u[n-1])`. Fixons les deux valeurs initiales à zéro. C’est une autre récurrence, pas un détail d’implémentation anodin.

Pour le mode rigide à `alpha=0.4`, l’équation caractéristique est `r^2-r+1.6=0`. Ses racines complexes ont pour module `sqrt(1.6)`, supérieur à un. L’itération sans retard au même gain a pour facteurs -0.6 et 0.6 et converge ; cette conclusion ne peut pas être transférée à la version retardée. Les déplacements de sa première coordonnée commencent par `[0,1.6,3.2,2.24,-1.28]` mm et ne donnent pas une trace d’erreur monotone.

### Exercice 4 : mettre en évidence l’hypothèse modifiée

Déduisez l’équation caractéristique du mode rigide et le module des racines pour la récurrence retardée. Pourquoi l’intervalle de gain précédent ne suffit-il pas à justifier cette boucle ?

> **Réponse:** La substitution d’un mode d’erreur proportionnel à `r^n` donne `r^2-r+alpha*4=0`, d’où `r^2-r+1.6=0`. Les racines conjuguées ont pour produit 1.6 et pour module `sqrt(1.6)>1`. La preuve précédente utilisait le résidu courant et une autre équation caractéristique. Des observations retardées peuvent nécessiter une autre analyse ; ce contre-exemple conçu pour le cours n’est pas une mesure d’un régulateur réel.

## 5. Comparer avec la résolution la plus simple

Pour cette matrice diagonale connue, la multiplication directe par `K^-1=diag(0.25,1)` donne immédiatement `[1,1]` mm. Une boucle d’agent ou un nouveau DSL doit justifier son surcoût par rapport à cette référence simple. Le [relevé antérieur de ressort conservé](https://github.com/spareilleux/learn/blob/d488be4c2fda37afa06a4f87e322b73f21e46313/code/streeling/evidence/weave-material-2026-10-22/directional-response.json) reste un calcul mathématique conçu pour le cours.

La [scène pédagogique](https://github.com/spareilleux/learn/blob/d488be4c2fda37afa06a4f87e322b73f21e46313/code/streeling/weave-godot/trial.gd) à la révision fixée crée des corps statiques. [Godot StaticBody3D](https://docs.godotengine.org/en/4.6/classes/class_staticbody3d.html) ne se déplace pas sous l’effet de forces externes ou de contacts ; ces corps n’implémentent pas notre solveur itératif de ressort.

### Exercice 5 : préparer une comparaison de solveurs avec l’aide des sources

Lisez la scène et la documentation des corps statiques, puis utilisez le [relevé fixé des itérations](../../../../code/streeling/evidence/constraint-feedback-2026-10-22/residual-iterations.json). Définissez une future comparaison délimitée avant qu’un agent ne promette une amélioration récursive.

> **Réponse:** Fixez la loi de réponse réelle, le repère, les unités, le gain, l’âge des observations, la politique de mise à jour et le critère d’arrêt. Comparez avec la résolution directe sur ce petit système connu et conservez séparément les résidus, les erreurs, les nombres d’itérations et les coûts en temps écoulé. Incluez des contrôles au gain limite, avec retard et avec des entrées invalides, puis testez toute extension non linéaire ou physique envisagée sous ses propres hypothèses. Rejetez un avantage revendiqué si l’orchestration ajoutée coûte davantage sans améliorer le résultat déclaré. Les présents calculs n’établissent ni solveur déployé, ni matériau étalonné, ni régulation en temps réel, ni amélioration générale des agents.
