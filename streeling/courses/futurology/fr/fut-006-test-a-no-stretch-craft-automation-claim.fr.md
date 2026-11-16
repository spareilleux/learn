---
module_id: fut-006-test-a-no-stretch-craft-automation-claim
department: futurology
course: "Tester une promesse d'automatisation créative sans étirement"
level: intermediate
prerequisites: ["fut-003-agent-substitution-readiness-drill", "phy-011-compute-bend-length-on-a-declared-neutral-layer", "sem-007-preserve-the-meaning-of-a-bend-angle"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Tester une promesse d'automatisation créative sans étirement

> **Portée du brouillon.** Calculs pédagogiques de surfaces idéales, contre-exemples de capacités et lecture de code et de documents primaires à une révision précise. Les revues humaines technique, artisanale, linguistique et pédagogique ainsi que la vérification du HTML du cours déployé restent à effectuer. Aucun développement en CAO, surface dans un environnement hôte, contrôle IX complet, export de maillage ou fabrication physique n'ont été réalisés.

## La question du projet

Un futur agent de création promet de transformer toute surface de scène en flan plat exact sans étirement. Avant d'estimer quand cette capacité arrivera, pouvons-nous énoncer un modèle et un cas qui réfuterait cette affirmation ? La prospective exige une cible délimitée et un test discriminant, et non un nom plus ambitieux pour un aperçu.

La [documentation de Rhino UnrollSrf](https://docs.mcneel.com/rhino/8/help/en-us/commands/unrollsrf.htm) distingue les surfaces développables de la mise à plat dépendante du matériau ou approchée et traite des coutures, des tolérances et des pièges. Elle indique aussi que ces outils n'ont pas été conçus pour le pliage et le dépliage de tôlerie comme les conduits. Lire la documentation n'est ni observer l'exécution d'une commande ni affirmer qu'un autre outil implémente le même comportement.

## 1. Tester la prémisse géométrique sans restriction

Le [guide de mathématiques des surfaces de Rhino](https://developer.rhino3d.com/en/guides/general/essential-mathematics/parametric-curves-surfaces/) définit la courbure de Gauss comme le produit des courbures principales. Dans les exemples pédagogiques en millimètres, un plan a pour courbures principales 0 et 0 ; un cylindre de rayon 10 a 0 et `1/10` ; une sphère de rayon 10 a `1/10` et `1/10`. Leurs courbures de Gauss sont 0, 0 et `1/100` en `mm^-2`.

Pour un développement exact, lisse et régulier préservant la métrique intrinsèque de la surface, une courbure de Gauss non nulle constitue un obstacle. La sphère réfute donc la promesse sans restriction de développement lisse sans étirement dans ce modèle. Cela ne prouve pas qu'une sphère ne peut pas être fabriquée, approchée par des panneaux ou formée en déformant le matériau. Ce sont des cibles et des procédés différents.

### Exercice 1 : situer un cas réfutant l'affirmation

Calculez les trois produits de courbures et identifiez un contre-exemple à la mise à plat exacte, lisse et sans étirement de toute surface. Ce contre-exemple réfute-t-il toutes les façons de fabriquer un objet sphérique ?

> **Réponse:** Les produits du plan et du cylindre valent 0 ; celui de la sphère vaut `1/100 mm^-2`. La sphère réfute la promesse sans restriction sous les hypothèses déclarées de régularité, de caractère lisse et d'absence d'étirement. Elle ne réfute ni un formage avec déformation, ni une approximation modifiée à facettes, ni un autre procédé de fabrication.

## 2. Préciser un cas positif abordable

Prenez un cylindre pédagogique idéal d'épaisseur nulle, de rayon 10 mm et de hauteur 30 mm. Une portion de quart de cylindre a une étendue angulaire de `pi/2` ; la coordonnée circonférentielle développée est la longueur d'arc `x=R*theta`, tandis que la coordonnée axiale reste inchangée. Sa largeur à plat est de `5*pi` mm et sa hauteur de 30 mm ; son aire est donc de `150*pi` mm carrés.

C'est un cas analytique positif pour une surface de référence choisie. Ce n'est ni un objet IX analysé, ni un flan produit, ni un pli d'épaisseur finie étalonné. [PHY-011](../../physics/en/phy-011-compute-bend-length-on-a-declared-neutral-layer.md) situe séparément une couche neutre dans un modèle pédagogique d'épaisseur. Le choix de la surface développée fait partie de la définition de la cible.

### Exercice 2 : rendre le jalon mesurable

Donnez les dimensions à plat et l'aire de la portion d'un quart. Quelles hypothèses de surface de référence et de procédé doivent rester attachées avant de présenter cela comme un futur jalon d'automatisation ?

> **Réponse:** La largeur est de `5*pi` mm, la hauteur de 30 mm et l'aire de `150*pi` mm carrés. Conservez le cylindre idéal d'épaisseur nulle, le rayon, l'étendue angulaire, la longueur axiale, les unités et la surface de référence choisie. Ces dimensions ne comprennent ni une règle de couche neutre étalonnée, ni un procédé physique de pliage, ni une exportation réussie depuis un environnement hôte.

## 3. Comparer les bonnes distances

À la même hauteur axiale, le chemin circonférentiel courbe du quart de cylindre a une longueur de `5*pi`, soit environ 15.707963268 mm. La corde spatiale entre ses extrémités vaut `10*sqrt2`, soit environ 14.142135624 mm. La corde passe dans l'espace à l'intérieur du cylindre ; ce n'est pas ce chemin sur la surface.

Un développement intrinsèque peut préserver le chemin courbe de la surface tout en modifiant la séparation euclidienne 3D de ses extrémités. Le rejeter parce que chaque corde spatiale n'est pas préservée testerait la mauvaise équivalence. Inversement, faire correspondre quelques cordes affichées ou une boîte englobante ne vérifierait pas la métrique de surface.

### Exercice 3 : éviter un faux rejet

Donnez les longueurs du chemin de quart de cercle et de la corde. Leur différence démontre-t-elle que le développement analytique a étiré la surface ? Précisez la longueur que le développement revendiqué préserve.

> **Réponse:** Le chemin sur la surface vaut `5*pi`, soit environ 15.707963268 mm ; la corde vaut `10*sqrt2`, soit environ 14.142135624 mm. Ils mesurent des chemins différents. Leur différence ne démontre pas un étirement de la surface : le développement préserve les longueurs intrinsèques des chemins sur la surface, et non chaque corde spatiale.

## 4. Nommer la couture dans une affirmation globale

La surface latérale entière du cylindre a une largeur de `20*pi` et une hauteur de 30 lorsqu'elle est ouverte le long d'une couture axiale ; son aire est de `600*pi` mm carrés. Avant la découpe, les paramètres angulaires 0 et `2*pi` identifient le même point de surface. Dans le rectangle, ils deviennent des côtés opposés du bord. Une correspondance de couture fait donc partie de cette construction ; elle ne prouve pas que la boucle fermée d'origine possédait déjà une carte rectangulaire unique sans découpe.

Une courbure de Gauss nulle est une propriété géométrique locale. Elle ne garantit pas à elle seule un développement global, sans découpe et injectif, ni un certificat de fabrication physique. La surface d'origine et sa carte ouverte doivent être comparées avec le traitement déclaré de la couture.

### Exercice 4 : contester une condition globale manquante

Donnez les dimensions et l'aire de toute la surface latérale ouverte. Quels points d'entrée confondus deviennent des côtés plats distincts, et pourquoi une courbure nulle n'établit-elle pas l'affirmation globale proposée sans découpe ?

> **Réponse:** Le rectangle mesure `20*pi` par 30 mm avec une aire de `600*pi` mm carrés. Les paramètres d'entrée 0 et `2*pi` désignent le même point du cylindre mais sont envoyés sur les côtés opposés de la couture. Une découpe choisie et une correspondance ouvrent cette boucle ; le test local de courbure nulle ne supprime pas l'exigence globale de couture.

## 5. Prévoir une capacité délimitée, puis exiger ses preuves

L'[ADR d'IX sur l'épaisseur à la révision fixée](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/docs/adr/0007-origami-thickness-as-parallel-rigid-panels.md#L7-L34) délimite sa lecture en panneaux parallèles séparément du rayon de pliage et du mouvement. Il ne fournit aucune preuve d'exécution pour les exemples de cylindres. Un aperçu, une vérification déclarée de pliage à plat, un développement idéal et un procédé de fabrication étalonné sont des capacités différentes.

Un jalon candidat plus petit consiste à comparer une portion de surface de référence déclarée à sa carte avec des tolérances explicites de longueur et d'aire et une correspondance de couture. Ses hypothèses sont une géométrie idéale régulière et le domaine choisi. Une objection forte est qu'une construction analytique manuelle pourrait déjà répondre au besoin immédiat de la scène, tandis qu'un nouvel adaptateur ajoute du travail de conversion, de validation et de maintenance. Cette alternative plus simple devrait être essayée avant de considérer un nouveau DSL comme nécessaire. Un échec de vérification métrique ou de couture réfuterait l'affirmation géométrique du candidat ; le rayon physique, l'épaisseur, la règle neutre, les dégagements, l'outillage, le retour élastique et le mouvement restent des obligations distinctes non résolues.

### Exercice 5 : corriger la prévision d'automatisation

Un agent transforme un cylindre visuellement plausible et un rapport d'empilement réussi en « toutes les surfaces de création fourniront des flans prêts à fabriquer ». Remplacez cette prévision par un candidat réfutable et identifiez les preuves encore requises.

> **Réponse:** Un candidat délimité développerait la portion cylindrique idéale déclarée, en conservant sa surface de référence, ses unités et ses coutures et en vérifiant les longueurs et l'aire intrinsèques selon les tolérances déclarées. Le contre-exemple de la sphère réfute la promesse sans restriction de développement lisse sans étirement. Un rapport d'empilement et un aperçu ne fournissent ni un adaptateur exécuté, ni une règle étalonnée d'épaisseur finie, ni des preuves de procédé. Comparez d'abord la construction analytique plus simple ; les résultats réels dans l'environnement hôte et en fabrication restent non vérifiés.

Le [relevé de portée](../../../../code/streeling/evidence/bend-development-2026-10-22/development-scope.json) conserve les cas positifs, les contre-exemples et les affirmations distinctes en attente. Aucun nouveau DSL de fabrication ni aucune politique de déploiement ne sont ratifiés par ces cours.
