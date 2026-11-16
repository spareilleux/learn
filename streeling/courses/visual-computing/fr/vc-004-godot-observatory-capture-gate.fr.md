---
module_id: vc-004-godot-observatory-capture-gate
department: visual-computing
course: "Une condition de capture pour l’observatoire Godot"
level: intermediate
prerequisites: [vc-002-godot-react-bridge-evidence]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
research_cycle: visual-computing-2026-10-11-004
version: "0.1.0"
---

# Une condition de capture pour l'observatoire Godot

> **Périmètre du brouillon et des traductions.** Le texte technique ci-dessous est un brouillon daté. Les mentions historiques de traductions, d’intégration dans Learn ou de vérifications de publication encore à faire concernent cette étape antérieure ; ce [dossier de traduction](../../../../code/streeling/evidence/locale-completion-2026-10-22/README.md) recense les brouillons actuels et les contrôles effectués. Les essais en conditions réelles encore non réalisés le restent. Les revues humaines du contenu et de la langue, ainsi que l’essai avec un apprenant, restent à effectuer.

> **Département d'informatique visuelle** | Niveau : intermédiaire | Durée estimée : 35 minutes | Statut : brouillon français ; révisions disciplinaire, pédagogique, linguistique et de publication en attente, dont l'approbation d'une personne maîtrisant le français

## Objectifs

Après cette leçon, vous saurez préciser quelles parties de l'observatoire Godot de GA sont étayées par les sources, définir une capture avant/après reproductible pour un changement de cadrage, calculer une zone de sécurité visuelle et un contrôle de répétabilité, puis prendre une décision d'acceptation délimitée qui inclut images et traces d'interaction.

## La question du projet

Un concepteur propose de déplacer la caméra de l'observatoire pour rendre plus lisibles la structure centrale de gouvernance et les nœuds de politique. Une capture paraît meilleure sur sa machine. Cela suffit-il pour remplacer la caméra de référence ? Que doit capturer, mesurer et conserver un réviseur pour permettre une vérification ultérieure de la décision ?

Le [plan d'intégration Godot à `dc2e74c`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/docs/plans/parked/2026-03-28-feat-godot-integration-plan.md) GA figé propose une scène de gravité constitutionnelle avec des nœuds de politique en orbite dans `Apps/ga-godot/` (Phase 2), un export web (Phase 4) et une boucle capture-vers-critique (Phase 5). Chacune de ces tâches est **non cochée** dans le plan figé. L'[hôte React `GodotScene.tsx`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/ReactComponents/ga-react-components/src/components/PrimeRadiant/GodotScene.tsx) déclare des modes panneau et plein écran, utilise par défaut `/godot/index.html` comme URL d'iframe et traite les messages `godot:ready` et `godot:node-clicked`. Ces déclarations étayent un futur chemin de visualisation et d'interaction, pas une scène rendue observée ni un pipeline de capture existant. Le plan se trouve sous `docs/plans/parked/` malgré son ancien en-tête « actif » ; aucun de ces libellés ne prouve une disponibilité à l'exécution.

Le commit GA examiné ne fournit pour cette leçon aucune scène Godot `.tscn`, export web ou résultat de capture vérifiés. Un prototype local distinct sans commit source versionné ne donnerait pas une citation stable ; il n'étaye donc pas les nombres ci-dessous. Cette leçon conçoit une évaluation **avant** qu'un tel changement de scène puisse être approuvé. Toutes les coordonnées, tous les décomptes et tous les résultats de la fixture d'exercice sont synthétiques. Aucun Godot, navigateur, critique de captures ou outil de mise à l'échelle n'a été exécuté ici.

## 1. Nommer le changement et figer ses contrôles

Une comparaison équitable exige une variable indépendante déclarée. Ici, c'est le **cadrage de caméra** d'une future scène Godot. Gardez fixes contenu de scène, instantané des données de gouvernance, ID des nœuds, viewport, échelle d'affichage, moteur de rendu, éclairage, réglages de qualité et révision du build pendant la capture des poses de référence et candidate. Consignez chaque pose : position, rotation, champ de vision ou réglage de projection et cible. Si la scène est animée, figez un instant ou une image nommés et désactivez toute graine aléatoire non contrôlée. Comparer deux captures où caméra et éclairage changent ne permet pas d'isoler ce qui rend une arête plus visible. Si l'expérience vise plutôt l'éclairage, le mode de rendu ou la mise à l'échelle, gardez la caméra fixe et consignez explicitement cette variable. Une comparaison de mise à l'échelle doit aussi consigner les résolutions interne de rendu et de sortie ; une grande image seule ne montre pas que le coût de rendu est identique.

Pour une future exécution, le manifeste de capture devrait nommer commit GA, commit du projet Godot, empreinte du build exporté, instantané de scène/données, moteur de rendu et version Godot, pose de caméra, viewport et échelle de l'appareil, image/instant et version de commande de capture. Attribuez à chaque PNG une ligne de manifeste, un horodatage et une empreinte de contenu. Capturez séparément les modes React **panneau** et **plein écran**, puisque l'hôte déclare les deux ; sélectionnez l'onglet Viewer du panneau, car son onglet Builder initial ne monte pas l'iframe. Ne supposez pas qu'un de ces modes charge actuellement un export Godot. Le dispositif de capture proposé devrait sauvegarder les PNG bruts et un manifeste lisible par machine ; un montage choisi aide la discussion mais ne remplace pas les images originales. Un réviseur humain pourra ainsi examiner le changement déclaré contre une référence stable sans se fier à sa mémoire.

### Exercice 1 : trier les preuves

Classez ces affirmations comme **étayée par la source**, **planifiée** ou **nécessite une exécution** : (a) l'hôte déclare une iframe dont la valeur par défaut est `/godot/index.html` ; (b) la scène de gravité constitutionnelle a été capturée trois fois dans le même navigateur ; (c) le plan figé inclut une boucle capture-vers-critique ; (d) une nouvelle pose améliore la lisibilité des nœuds.

> **Réponse :** (a) est étayée par `GodotScene.tsx`. (c) est planifiée en Phase 5 non cochée. (b) nécessite un véritable export, un navigateur et trois captures sauvegardées ; aucun n'a été observé ici. (d) exige une tâche de lisibilité définie et des données comparatives. Une entrée de plan ou une chaîne source d'iframe ne remplace pas ces observations.

## 2. Tester une affirmation visuelle avec des images

Supposons que la future scène possède trois nœuds cibles connus, A, B et C, visibles depuis trois points de vue nommés. Une caméra candidate devrait maintenir les marques cibles dans un **rectangle de sécurité** laissant cinq pour cent de la largeur et de la hauteur de sortie à chaque bord. Cette marge est un seuil de projet proposé, pas une valeur Godot par défaut ni une norme d'accessibilité. À 1280 × 720 pixels, l'intervalle x sûr vaut `[64, 1216]` et l'intervalle y `[36, 684]`. Toute la boîte englobante annotée de la cible doit y entrer, pas seulement son centre. L'annotation devrait inclure l'ID cible et les coordonnées du rectangle dans le PNG brut de sortie. Pour chaque point de vue nommé, capturez trois images répétées sous les mêmes valeurs de manifeste et calculez le plus grand changement de coordonnée de chaque bord entre répétitions. Exigez au maximum **deux pixels** de dérive. C'est un seuil de répétabilité proposé, pas une mesure du projet.

La zone de sécurité détecte rognage et encombrement des bords ; elle n'établit ni la lisibilité d'un libellé, ni la distinction d'une couleur, ni la fidélité des indices de profondeur. Une tâche humaine proposée consiste à identifier A, B et C sans superposition des réponses, utilisée seulement pour noter le résultat. Consignez erreurs et raisons, puis comparez candidat et référence sous les mêmes tâche et conditions. Un critique de captures peut signaler des cadrages suspects ou des libellés illisibles, mais son score exige un calibrage sur ces résultats avant de servir de condition. Un seuil de différence de pixels entre référence et candidat serait inadapté à un déplacement volontaire de caméra : la différence prouve un changement, pas une amélioration. Utilisez les différences entre répétitions pour tester la stabilité des captures, et les résultats de tâche pour tester l'utilité.

### Exercice 2 : contrôler la comparaison

Deux captures possèdent les mêmes données de nœuds et taille de sortie, mais le candidat change à la fois pose de caméra et éclairage et son PNG n'a pas d'empreinte de build. Cette paire isole-t-elle l'effet de caméra ? Nommez les corrections minimales.

> **Réponse :** Non. Figez le build de scène/export et l'instantané de données, consignez l'empreinte du build et les réglages de caméra, puis gardez fixes éclairage et autres contrôles de rendu pour comparer la caméra. Sauvegardez les images brutes et le manifeste. Évaluez l'éclairage séparément à caméra fixe. Sans ces contrôles, une meilleure lisibilité peut venir de l'un ou l'autre changement ou d'un build inconnu.

### Exercice 3 : calculer la zone de sécurité

Dans une sortie **synthétique** de 1280 × 720, les boîtes candidates sont A `(80, 50)–(180, 130)`, B `(60, 50)–(160, 130)` et C `(90, 40)–(190, 120)`. Lesquelles respectent la marge proposée de cinq pour cent et quel déplacement horizontal minimal ferait entrer le bord gauche de B ?

> **Réponse :** Les bornes sûres sont x `64–1216` et y `36–684`. A et C entrent. B échoue, car son bord gauche vaut `60 < 64` ; un déplacement d'au moins quatre pixels vers la droite le placerait à 64. Un vrai déplacement de caméra peut déplacer toutes les marques ; les trois boîtes nécessiteraient donc de nouvelles captures et vérifications. Ce calcul ne décrit pas une image Godot observée.

## 3. Vérifier la répétabilité avant de juger l'amélioration

Des réglages identiques devraient produire des images comparables. Pour les cibles statiques, calculez la dérive des bords sur chaque série de trois répétitions ; conservez les trois images plutôt que la meilleure seule. Si la scène comporte un mouvement intentionnel, définissez un pas de simulation fixe ou comparez un repère stable. Si cela reste incontrôlable, rapportez une distribution sur plusieurs captures plutôt qu'une répétabilité au pixel. Consignez aussi le chargement et le comportement des images : un réglage améliorant le cadrage mais rendant l'export web inutilisable ne peut satisfaire la condition complète. Mesurez le temps par image sur le même appareil et navigateur pendant une exécution définie, avec médiane et valeurs de queue de distribution ; ne le déduisez pas de la taille des images ou de la fluidité apparente d'un enregistrement. Cette leçon n'impose pas de budget de performance non mesuré au futur export.

Le callback de disponibilité de l'hôte React peut aider un futur dispositif à savoir quand l'iframe se dit prête, mais le gestionnaire figé accepte des messages répétés et ne prouve pas une image rendue. Sa comparaison de source de message s'applique lorsque la référence d'iframe existe ; il ne valide ni origine ni `nodeId` à l'exécution. Comme l'explique [VC-002](vc-002-godot-react-bridge-evidence.md), une future vérification devrait consigner une image réelle et des clics intentionnels sur les nœuds, pas seulement la disparition d'un indicateur de chargement. Les preuves visuelles et d'interaction occupent des colonnes distinctes.

### Exercice 4 : tester la répétabilité des captures

Pour le bord gauche d'une cible, trois captures répétées **synthétiques** donnent les x `80`, `81` et `84`. Respectent-elles la dérive maximale proposée de deux pixels ? Que doit faire le réviseur avant de comparer la qualité visuelle à la référence ?

> **Réponse :** Non. Le maximum moins le minimum vaut `84 − 80 = 4` pixels, au-delà de deux. Conservez les trois PNG, vérifiez si caméra, viewport, instant de scène, animation et données étaient vraiment fixes et recapturez après identification de la cause non contrôlée. Choisir la seule image x = 80 masquerait l'instabilité.

## 4. Écrire une condition capable de refuser une belle capture

Une condition d'acceptation proposée pour un futur export Godot versionné comporte des étapes ordonnées. D'abord, établir la provenance du build, un export servi, un événement de disponibilité **et** une capture rendue ; sinon la comparaison visuelle est **non évaluable**. Ensuite, recueillir les PNG bruts de référence et candidat en panneau et plein écran aux vues nommées, trois répétitions chacune et manifestes complets. Troisièmement, exiger chaque boîte connue dans le rectangle sûr et une dérive de répétition statique inférieure ou égale à deux pixels. Quatrièmement, effectuer une tâche d'identification sur les mêmes ID connus et exiger un candidat au moins aussi bon que la référence. Cinquièmement, dans un hôte de test dédié avec iframe montée, exiger **20/20 clics intentionnels connus** livrés dans l'ordre aux ID React attendus et **zéro** callback de messages injectés depuis une source étrangère. Ce dernier seuil est une vérification proposée après existence d'un export réel, pas un résultat de cette leçon ; un hôte produit fermant ou changeant de vue au clic exige une trace distincte de retour. Consignez échecs et réussites et conservez le journal brut des événements avec les images.

Cette condition est volontairement conjonctive : une étape échouée bloque la décision. Elle ne certifie ni qualité artistique ni accessibilité. [VC-001](vc-001-accessible-fretboard-paths.md) impose séparément de préserver l'accès clavier et lecteur d'écran. Une proposition de mode de rendu ou mise à l'échelle exigerait aussi sa propre matrice d'appareils et un budget de temps par image mesuré ; les sources GA figées ne démontrent ni fork DLSS, ni moteur particulier, ni outil de mise à l'échelle. Approuver un changement de caméra sur un tableau synthétique serait une erreur de catégorie. Le tableau sert uniquement à exercer la logique de la condition.

| Candidat hypothétique | Build, disponibilité, image rendue, captures brutes | Boîtes sûres et dérive | Identification face à la référence | Trace de clics dédiée |
|---|---|---|---|---|
| X | Complets | Bord gauche B 60 ; dérive 4 px | Égale | 20/20 ; étrangers 0 |
| Y | Complets | Toutes sûres ; dérive 2 px | Égale | 19/20 ; étrangers 0 |
| Z | Complets | Toutes sûres ; dérive 2 px | Égale | 20/20 ; étrangers 0 |

### Exercice 5 : décider sans choisir seulement les résultats favorables

Appliquez la condition à X, Y et Z. Quel candidat hypothétique satisfait les vérifications de la **fixture** ? Quelles preuves supplémentaires sont requises avant d'accepter un vrai changement de caméra d'observatoire ?

> **Réponse :** X échoue aux vérifications de zone de sécurité et répétabilité malgré sa trace de clics parfaite. Y échoue à l'exigence de 20/20 clics malgré ses images acceptables. Z satisfait toutes les colonnes synthétiques listées. Aucun n'est un résultat Godot observé. Une vraie décision exige encore scène/export versionnés, captures brutes et manifestes reproductibles, résultats réels de tâche et traces d'événements, examen d'accessibilité et de sens visuel et tout seuil convenu de performance sur appareil.

## Points à retenir et limites des preuves

- Un plan figé peut motiver un protocole de capture sans prouver l'exécution de la scène, de l'export ou du critique prévus.
- Pour comparer les caméras, faites varier la caméra en gardant fixes scène, données, moteur, éclairage, viewport et instant de capture. Consignez les entrées et préservez les images brutes.
- Les calculs de zone de sécurité et dérive rendent la capture vérifiable ; réussite aux tâches et traces de clics répondent à d'autres questions. Une belle capture unique ne les remplace pas.
- Les cinq exercices utilisent des boîtes et résultats inventés. Les seuils de cinq pour cent, deux pixels et 20/20 clics sont des critères proposés, pas des références GA mesurées.
- Aucune capture Godot active, alimentation de données IX/Gaia, mesure de mise à l'échelle, révision humaine disciplinaire, essai d'apprenant ou publication n'est revendiqué ici. Le cycle source anglais antérieur ne revendiquait pas non plus de traduction ; ce brouillon français attend l'approbation d'une personne maîtrisant le français.

*Recherche : `visual-computing-2026-10-11-004`. Brouillon français ; révision et publication en attente.*
