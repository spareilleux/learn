---
module_id: phy-008-keep-surface-normals-perpendicular
department: physics
course: "Garder les normales perpendiculaires aux surfaces"
level: intermediate
prerequisites: ["phy-005-sheet-thickness-and-scene-units", "cs-014-compose-brutal-scene-descriptions"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Garder les normales perpendiculaires aux surfaces

> **Périmètre du brouillon.** Nouvelle exécution sur CPU des fonctions géométriques publiques inchangées de BRUTAL, avec des entrées conçues pour l'exercice, des calculs mathématiques indépendants et l'inspection du code du moteur de rendu à une révision précise. Les revues technique, linguistique et pédagogique humaines, ainsi que la vérification du HTML du cours déployé, restent à faire. Aucun shader, hôte Colossus, GPU ni application Blender ou Godot n'a été exécuté.

## La question du projet

Un agent étire une pièce sculptée et fait pivoter un composant enfant. Les positions semblent mathématiquement valides, mais peut-on encore utiliser un axe local transformé comme normale à la surface ? Une normale indique une direction perpendiculaire à une surface. L'éclairage et l'échantillonnage des surfaces peuvent utiliser cette direction ; préserver les positions ne suffit donc pas.

Ce cas provient des [conventions spatiales publiques de BRUTAL](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Space.fs) et de sa [composition imbriquée](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Generate.fs#L165), à la révision GA `76efbffd5af82b46c3146957a6bd4504008eeb89`. Les matrices agissent sur des vecteurs lignes, et la matrice monde d'un enfant est sa matrice locale multipliée par celle de son parent. [CS-014](../../computer-science/en/cs-014-compose-brutal-scene-descriptions.md) présente cet ordre ; ici, nous testons un invariant géométrique après composition.

## 1. Tester la perpendicularité, pas seulement la longueur unitaire

Considérons une face locale de boîte dont la normale sortante suit X positif et dont les tangentes suivent Y et Z. Après une transformation linéaire inversible, une normale valide doit encore avoir un produit scalaire nul avec les deux tangentes transformées. Normaliser un vecteur ramène sa longueur à un ; cela ne corrige pas sa direction.

La [démonstration de PBRT](https://pbr-book.org/4ed/Geometry_and_Transformations/Applying_Transformations) déduit la règle de la transposée de l'inverse de cette condition de perpendicularité. Gardez la convention matricielle explicite quand vous utilisez la formule. Le programme natif de vérification pédagogique appelle [Vector3.TransformNormal de .NET](https://learn.microsoft.com/dotnet/api/system.numerics.vector3.transformnormal?view=net-10.0), soit avec la matrice monde, soit avec la transposée de son inverse calculée explicitement. Le nom de la méthode ne fait pas ce choix à la place de l'appelant.

### Exercice pratique 1 : rejeter une normale normalisée mais inclinée

Une normale candidate unitaire a un produit scalaire de 0.6 avec une tangente unitaire à la surface. La normalisation en a-t-elle fait une normale valide ? Indiquez un test portant sur la propriété manquante.

> **Réponse:** Non. Un produit scalaire non nul signifie que la candidate n'est pas perpendiculaire à cette tangente. Testez ses produits scalaires avec deux tangentes transformées indépendantes, selon une tolérance numérique déclarée. La longueur unitaire est une propriété distincte ; renormaliser la même direction ne peut pas annuler ce produit scalaire de 0.6.

## 2. Composer un cas qui met le raccourci en défaut

Plaçons une rotation de lacet de 45 degrés d'un enfant sous une mise à l'échelle parent de `(2,1,1)`. Dans la convention des vecteurs lignes, la matrice monde linéaire est `R45*S`. Ses axes locaux X et Z transformés sont `(sqrt2,0,-1/sqrt2)` et `(sqrt2,0,1/sqrt2)`. Leur produit scalaire brut vaut 1.5 : les axes ne sont donc pas perpendiculaires. Leurs longueurs valent toutes deux `sqrt(2.5)`, et leur produit scalaire après normalisation vaut 0.6.

Ce cisaillement effectif résulte de la composition. Dans l'ordre témoin `S*R45`, les axes mis à l'échelle tournent ensemble et restent perpendiculaires. Une seule mise à l'échelle non uniforme de ces faces de boîte alignées sur les axes ne produit pas automatiquement le même écart. Les [cas natifs réellement exécutés](../../../../code/streeling/evidence/scene-frames-2026-10-22/native-cases.json) conservent les deux ordres, plutôt que d'attribuer toute erreur à la seule mise à l'échelle.

### Exercice pratique 2 : distinguer les deux compositions

Calculez les produits scalaires brut et normalisé des axes X/Z imbriqués indiqués. Pourquoi un témoin avec mise à l'échelle suivie du lacet est-il utile ?

> **Réponse:** Le produit scalaire brut vaut `2-0.5=1.5` ; le diviser par le produit des longueurs, soit 2.5, donne 0.6. Dans l'ordre mise à l'échelle puis lacet, les axes transformés de la boîte restent perpendiculaires. Le témoin montre que l'ordre de composition et la géométrie de la base qui en résulte comptent ; la mise à l'échelle non uniforme ne suffit pas, à elle seule, à expliquer ce contre-exemple.

## 3. Comparer directement les deux directions

Pour cette face, normaliser l'axe X transformé donne `(2/sqrt5,0,-1/sqrt5)`. Appliquer la transposée de l'inverse puis normaliser donne `(1/sqrt5,0,-2/sqrt5)`. Cette dernière direction a un produit scalaire nul avec la tangente Z transformée ; la première a un produit scalaire normalisé de 0.6. Le cosinus entre les deux candidates vaut 0.8, ce qui correspond à environ 36.869897646 degrés.

La [comparaison des normales](../../../../code/streeling/evidence/scene-frames-2026-10-22/normal-comparison.json) distingue les expressions exactes des calculs effectivement réalisés par les fonctions natives en float32. Les vérifications natives utilisent la tolérance `1e-5`. Il s'agit de directions calculées, pas d'erreurs mesurées en pixels ni d'une preuve qu'un spectateur a remarqué un changement d'éclairage.

### Exercice pratique 3 : vérifier la correction

À partir des deux candidates unitaires indiquées et de la tangente Z unitaire `(2/sqrt5,0,1/sqrt5)`, calculez le produit scalaire de chaque candidate avec la tangente, puis le cosinus entre les candidates. Quel invariant sélectionne la direction perpendiculaire ?

> **Réponse:** La candidate issue de l'axe transformé donne `(4-1)/5=0.6` ; celle issue de la transposée de l'inverse donne `(2-2)/5=0`. Le cosinus entre les candidates est `(2+2)/5=0.8`. La perpendicularité sélectionne la seconde direction pour cette face transformée. L'écart d'environ 36.869897646 degrés est géométrique ; ce n'est pas une note de qualité visuelle observée.

## 4. Repérer la frontière du code qui utilise la direction

Le [shader de rastérisation inspecté](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs#L453) utilise déjà une transposée de l'inverse. Un [chemin distinct d'échantillonnage des faces pour l'essaim](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs#L3625-L3638) normalise un axe transformé de la boîte et calcule l'aire de la face à partir du produit vectoriel des autres axes. Lorsque les axes transformés sont orthogonaux, ces directions normales concordent ; le cas composé conçu pour l'exercice révèle une hypothèse plus restrictive.

Le [reçu de cette nouvelle exécution](../../../../code/streeling/evidence/scene-frames-2026-10-22/native-execution.json) consigne l'utilisation autonome des fonctions publiques F# et de brouillons pédagogiques construits explicitement. Il n'exécute aucun des deux chemins de Colossus, aucune requête de scène intégrée ni le parcours de génération. Le désaccord établi à l'aide du code pour un placement construit constitue un candidat à tester. Il n'établit pas un défaut visible dans les scènes intégrées actuelles ou dans un moteur de rendu déployé.

### Exercice pratique 4 : rédiger un constat technique délimité

Un agent affirme : « L'éclairage de BRUTAL est cassé pour tous les objets étirés. » Remplacez cette affirmation par les preuves réelles et par la prochaine vérification permettant de trancher.

> **Réponse:** Le shader de rastérisation à la révision inspectée utilise des normales issues de la transposée de l'inverse ; l'échantillonneur de faces distinct utilise des axes transformés. Un lacet imbriqué sous une mise à l'échelle non uniforme, construit pour l'exercice, rend cette dernière direction non perpendiculaire dans les calculs CPU, tandis que le témoin orthogonal donne des directions concordantes. Il faut ensuite exécuter le véritable échantillonneur sur ce placement et vérifier ses consommateurs et sa sortie avant d'affirmer qu'il existe un défaut de rendu ou un défaut visible. Aucune exécution de cet hôte n'a eu lieu ici.

## 5. Traiter séparément la singularité

Le [validateur existant](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Validate.fs) vérifie que les dimensions locales des boîtes sont positives et finies et que les éléments des matrices de placement sont finis. Dans les brouillons pédagogiques réellement testés, une échelle X nulle passe ces vérifications, mais son déterminant vaut 0 et sa matrice n'a pas d'inverse. Une dimension locale négative et un placement contenant NaN sont refusés. On peut encore calculer les bornes de la boîte aplatie ; elles ne certifient ni un solide non dégénéré ni une normale exploitable par la transposée de l'inverse.

Une règle proposée pour un hôte pourrait refuser les placements singuliers lorsqu'un consommateur exige un inverse. L'objection est qu'un autre consommateur peut volontairement accepter une primitive aplatie. Restreindre les transformations prises en charge peut être plus simple qu'étendre tous les échantillonneurs. Les deux approches exigent un besoin défini du consommateur et des tests de compatibilité ; ce cours ne modifie ni le validateur ni un contrat public. [SEM-006](../../semiotics/en/sem-006-preserve-orientation-across-scene-frames.md) traite l'orientation séparément de l'inversibilité.

### Exercice pratique 5 : ne pas transformer une acceptation en garantie

Un brouillon à échelle nulle a été accepté et possède des bornes finies. Un agent peut-il affirmer que tous les hôtes peuvent calculer son éclairage sans problème ? Quelles preuves justifieraient une vérification supplémentaire ?

> **Réponse:** Non. La vérification observée porte sur la forme locale et sur les valeurs finies du placement, alors que la matrice à échelle nulle est singulière. Un consommateur qui exige une inversion a besoin d'une règle explicite de traitement et d'un test réel de ce chemin. Prouver que le consommateur n'a jamais besoin d'un inverse, ou qu'il traite délibérément le cas aplati, affaiblirait la justification d'un rejet systématique. Acceptation, bornes finies, normales correctes et rendu observé restent des résultats distincts.
