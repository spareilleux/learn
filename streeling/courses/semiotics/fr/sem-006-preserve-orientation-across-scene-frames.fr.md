---
module_id: sem-006-preserve-orientation-across-scene-frames
department: semiotics
course: "Préserver l'orientation entre les repères d'une scène"
level: intermediate
prerequisites: ["sem-004-face-identity-under-reindexing", "cs-014-compose-brutal-scene-descriptions"]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Préserver l'orientation entre les repères d'une scène

> **Périmètre du brouillon.** Code de BRUTAL à une révision précise, véritables vérifications CPU des matrices et de la validation, et calculs sur un triangle conçu pour l'exercice. Les revues technique, linguistique et pédagogique humaines, ainsi que la vérification du HTML du cours déployé, restent à faire. Aucun import Blender/Godot, test de caméra, calcul GPU ni essai de fabrication n'a été effectué.

## La question du projet

Un agent artisan nomme un côté d'un composant « X positif » ou « avant ». Un autre agent applique une réflexion à la pièce pour une scène. L'étiquette désigne-t-elle toujours le même côté de la matière, la même direction dans le monde ou la face que verra une caméra ? Ces interprétations peuvent diverger sans que le composant perde son identité.

[SEM-004](sem-004-face-identity-under-reindexing.md) conserve les références à la matière lors d'une renumérotation. Ici, le changement est spatial : la [convention de repère de BRUTAL à la révision inspectée](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Space.fs) définit le mètre comme unité, Y positif vers le haut, X positif vers l'est et Z positif vers le sud. Les noms locaux des faces et les descriptions selon les axes du monde doivent s'interpréter dans ce contexte, plutôt que comme des chaînes interchangeables.

## 1. Nommer l'objet et son interprétation

Prenons le côté local X positif d'un solide construit pour l'exercice. Sa référence à la matière identifie le côté choisi ; sa normale locale exprime la direction de ce côté avant placement. Une normale monde décrit la direction transformée. L'ordre des sommets d'un triangle décrit une convention d'orientation, tandis que la visibilité dépend aussi de la caméra, du matériau et des règles de l'hôte. Un mot destiné à l'utilisateur, comme « avant », ne détermine pas tous ces champs.

Dans le placement composé de [PHY-008](../../physics/en/phy-008-keep-surface-normals-perpendicular.md), la même face locale X positif possède la normale monde `(1/sqrt5,0,-2/sqrt5)`. L'appeler « X positif du monde » changerait donc l'interprétation. Préserver la sélection dans la matière n'oblige pas à prétendre que sa direction dans le monde est restée fixe.

### Exercice pratique 1 : corriger une étiquette de côté ambiguë

Un agent affirme : « L'avant ne change pas après placement. » Quelles distinctions manquent ? Reformulez l'affirmation pour le côté X positif conçu pour l'exercice.

> **Réponse:** L'affirmation omet le côté sélectionné dans la matière, le repère source, la transformation, la direction obtenue et le sens donné à « avant ». Une affirmation délimitée serait que le même côté local X positif reste sélectionné après le placement déclaré, avec pour normale monde `(1/sqrt5,0,-2/sqrt5)`. Ni la visibilité depuis la caméra ni le classement comme face avant par un hôte n'ont été testés. L'identité de la sélection n'implique pas une direction fixe dans le monde.

## 2. Une réflexion change l'orientation

Prenons le triangle pédagogique de sommets `(1,-1,-1)`, `(1,1,-1)` et `(1,-1,1)`. Le produit vectoriel ordonné de ses arêtes vaut `(4,0,0)`, dans la direction du côté sortant X positif choisi. Appliquons une réflexion selon X en conservant l'ordre des sommets. Tous les sommets passent à X égal à -1, mais leur produit vectoriel ordonné reste `(4,0,0)`. La direction sortante transformée est X négatif : l'ordre conservé et cette interprétation sortante ne concordent plus.

Permuter les deux derniers indices de sommets donne le produit vectoriel `(-4,0,0)`. Cela rétablit la concordance pour la convention sortante déclarée. Ce n'est pas une preuve du classement des faces avant par un moteur de rendu particulier. Le [relevé d'orientation](../../../../code/streeling/evidence/scene-frames-2026-10-22/orientation-controls.json) conserve le triangle pédagogique, le déterminant et le raisonnement sur les produits vectoriels séparément des observations sur les matrices natives.

### Exercice pratique 2 : suivre le triangle réfléchi

Donnez le produit vectoriel initial, celui obtenu après réflexion selon X sans changer l'ordre et celui obtenu après permutation des deux derniers indices. Quelle direction a été choisie comme côté sortant après réflexion ?

> **Réponse:** Ces produits valent respectivement `(4,0,0)`, `(4,0,0)` et `(-4,0,0)`. Le côté sortant après réflexion est X négatif. La réflexion change la relation entre l'ordre inchangé des sommets et l'orientation sortante choisie ; elle n'efface pas la référence à la matière et ne constitue pas une observation par caméra.

## 3. Deux changements de signe ne sont pas nécessairement une réflexion

Les témoins sur les matrices natives donnent un déterminant de -1 pour la réflexion selon X seul, de +1 pour des changements de signe simultanés de X/Z et de +1 pour un lacet de 180 degrés. Les signes positif et négatif du déterminant distinguent la conservation et l'inversion de l'orientation pour ces applications inversibles. Un déterminant nul est un cas singulier distinct ; il ne peut pas être classé comme un changement de repère inversible.

Le [placement de Colossus inspecté](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs#L2273-L2278) comprend un lacet de pi. Il inverse X et Z ensemble par une rotation. Le qualifier de changement de chiralité au seul motif que X change de signe décrirait mal l'application. Le calcul natif du lacet en float32 est vérifié avec la tolérance `1e-5`, sans exiger que le sinus à 180 degrés soit représenté par un zéro exact.

### Exercice pratique 3 : distinguer rotation, réflexion et écrasement

Classez, selon leur déterminant, l'échelle X seule `(-1,1,1)`, l'échelle à deux signes négatifs `(-1,1,-1)` et l'échelle X nulle `(0,1,1)`. Laquelle a le même effet de rotation conservant l'orientation qu'un lacet de 180 degrés ?

> **Réponse:** Leurs déterminants sont -1, +1 et 0. La première inverse l'orientation ; la seconde la conserve et a le même effet idéal sur les axes qu'un lacet de 180 degrés ; la troisième écrase une dimension et n'a pas d'inverse. Le changement de signe d'une coordonnée nommée ne suffit pas à classer la transformation complète.

## 4. Interpréter la convention de l'hôte destinataire

La [référence officielle de SurfaceTool dans Godot](https://docs.godotengine.org/en/stable/classes/class_surfacetool.html) déclare un ordre horaire des sommets pour les faces avant des modes de primitives triangulaires. C'est une convention de l'hôte à consulter lors d'un véritable test d'adaptateur. Elle ne permet pas à cet exemple CPU de déduire la visibilité avant/arrière sans connaître la géométrie complète, la caméra et les conditions du matériau. Il faut explicitement réconcilier la direction mathématique du produit vectoriel et la règle des faces avant.

Le [chemin des instances pour les rayons inspecté dans BRUTAL](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs#L4520) désactive l'élimination des triangles selon leur orientation. Ce réglage dans le code ne prouve ni que tous les autres chemins appliquent la même politique, ni que les géométries réfléchies ou singulières sont prises en charge de manière générale. Aucun hôte n'a été exécuté pour cette leçon.

### Exercice pratique 4 : délimiter l'affirmation sur l'adaptateur

Un agent change le signe d'un vecteur normal, lit la convention de Godot et affirme que la géométrie réfléchie s'importe correctement. Que manque-t-il encore ?

> **Réponse:** Il manque l'ordre réel des sommets et des indices après conversion, les normales, la transformation complète, les réglages de primitive, de matériau et d'élimination des faces chez le destinataire, ainsi qu'une observation contrôlée dans l'hôte. Modifier une normale ne réécrit pas à lui seul les indices des triangles, et lire une documentation n'exécute pas un import. Testez l'adaptateur réel avec des témoins connus de rotation et de réflexion avant d'affirmer que l'import ou la visibilité sont corrects.

## 5. Transmettre le sens nécessaire à la décision suivante

Une transmission utile peut conserver la référence sélectionnée dans la matière, le repère local, la transformation complète, la convention sortante choisie, l'ordre des indices et la règle visée chez l'hôte destinataire. Ce sont des besoins d'information proposés pour un adaptateur, pas un nouveau schéma implémenté. L'objection est que transporter tous ces champs peut être inutile pour une tâche qui se limite à cadrer une caméra autour des bornes. L'alternative plus simple consiste à déclarer cette tâche limitée et à ne préserver que les données suffisantes, sans en faire une garantie d'orientation des surfaces.

Le [reçu natif](../../../../code/streeling/evidence/scene-frames-2026-10-22/native-execution.json) consigne les appels aux matrices et au validateur sur les brouillons pédagogiques. Il n'établit ni un service persistant d'identifiants de côtés ni un export de scène. [INF-006](../../information-theory/en/inf-006-know-what-scene-bounds-forget.md) montre pourquoi un résumé par les bornes peut rester utile tout en perdant la géométrie intérieure.

### Exercice pratique 5 : rédiger une transmission qui tient compte de l'orientation

Rédigez une courte transmission pour le triangle pédagogique réfléchi. Indiquez une condition dans laquelle ces informations seraient insuffisantes pour la tâche suivante.

> **Réponse:** Conservez la référence au côté local X positif dans la matière, la transformation de réflexion selon X de déterminant -1, la direction sortante réfléchie X négatif et l'ordre réel des indices, en précisant si les deux derniers ont été permutés. Indiquez que l'import dans l'hôte et la visibilité ne sont pas testés. Ces champs ne définissent toujours ni les UV, ni les tangentes d'ombrage, ni les matériaux, ni toutes les règles de l'hôte ; une tâche qui en dépend exige des preuves supplémentaires, plutôt qu'une affirmation de compatibilité sans fondement.
