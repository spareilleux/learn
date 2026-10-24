---
title: Tester le sens des états de pli dans une scène Blender-vers-Godot
description: Tester le sens des états de pli dans une scène Blender-vers-Godot — Informatique visuelle
sidebar:
  label: VC-006 · Tester le sens des états de pli dans une scène Blender-vers-Godot
  order: 6
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/visual-computing/fr/vc-006-origami-fold-state-scene-trial.fr.md
---

:::note[Streeling University]
**VC-006** · Tester le sens des états de pli dans une scène Blender-vers-Godot · intermédiaire · 40 minutes

Généré par le département *Informatique visuelle* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/visual-computing/fr/vc-006-origami-fold-state-scene-trial.fr.md) · [Mon journal](../../journal/)

Prérequis: [VC-005](../../visual-computing/vc-005-craft-details-through-blender-to-godot/)
:::

> **Périmètre de la source et du transfert.** Le texte technique ci-dessous provient d’un brouillon archivé. Les mentions historiques de traductions encore à rédiger, d’une absence d’importation ou de compilation dans Learn concernent cette étape antérieure ; ce [dossier de transfert](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/representation-release-2026-10-22/README.md) décrit les brouillons de traduction actuels, l’importation et ses vérifications. Les autres expériences indiquées comme non réalisées le restent. Les revues humaines du contenu et de la langue, ainsi que l’essai avec un apprenant, restent à effectuer.

> **Département d'informatique visuelle** | Intermédiaire | 40 minutes | Brouillon français ; aucun asset plié, import Godot, essai d'apprenant, révision humaine ou publication ; approbation par une personne maîtrisant le français en attente

## Objectifs et question du projet

Après cette leçon, vous saurez définir un petit essai de scène à surface pliée, distinguer géométrie, matériau et sémantique du pli, diagnostiquer la perte d'un indice d'état et rédiger des critères capables de rejeter un asset séduisant mais trompeur. **Question du projet :** un panneau de gouvernance pliable dans l'observatoire Godot proposé de GA pourrait-il montrer deux états de politique distincts tout en préservant l'état que l'apprenant peut identifier ? C'est une conception de test. Elle n'affirme pas l'existence d'un objet origami, d'un DSL d'états de pli ou d'une scène Godot fonctionnelle.

Le [plan d'intégration Godot](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/docs/plans/parked/2026-03-28-feat-godot-integration-plan.md) GA figé esquisse une scène de gravité constitutionnelle et du travail de retour sur captures d'écran sous forme d'éléments non cochés. L'[hôte Godot React](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/ReactComponents/ga-react-components/src/components/PrimeRadiant/GodotScene.tsx) figé déclare une iframe et une gestion de messages ; il ne prouve pas qu'une scène a été exportée. [VC-004](../../visual-computing/vc-004-godot-observatory-capture-gate/) propose une condition de capture reproductible et [VC-005](../../visual-computing/vc-005-craft-details-through-blender-to-godot/) traite de la préservation des petits détails artisanaux pendant le nettoyage GLB. Ici, le problème central est différent : une arête visible peut subsister alors que l'*identité, la direction ou le sens politique* du pli disparaît.

## 1. Définir le contrat d'état de pli avant la modélisation

Utilisez une **fixture synthétique** volontairement petite : trois panneaux étiquetés A, B et C avec deux charnières. Le pli `e1` joint A à B ; le pli `e2` joint B à C. Un manifeste d'essai externe attribue à chaque pli un ID, les ID des panneaux incidents, un état et une étiquette sémantique. Dans l'exemple, l'état `closed` signifie que `e1` est un pli montagne et `e2` un pli vallée ; l'état `open` signifie que les deux panneaux sont revenus à une pose quasi plate déclarée. Montagne et vallée nomment l'orientation signée de la fixture, pas une lecture universelle d'un maillage arbitraire. Fixez l'ordre des sommets des faces, la direction du pli, le côté d'observation et une convention de signe dans le manifeste avant de consigner les angles. Sinon, inverser la vue ou les normales pourrait inverser l'étiquette sans déplacer de sommet.

Pour l'observatoire proposé, donnez à `closed` le sens d'essai « une dépendance de politique est retenue » et à `open` « la dépendance est disponible ». Ce sont des sens d'interface inventés, pas des affirmations sur un protocole de gouvernance existant ou une tradition historique d'origami. Gardez le manifeste hors du maillage exporté et associez ses ID de plis stables aux objets de scène après import. Un asset affichant deux belles poses sans correspondance `e1`/`e2` récupérable ne peut satisfaire l'exigence d'interaction de cet essai.

### Exercice 1 : trouver le contrat manquant

Un modeleur fournit deux captures étiquetées `open` et `closed`, plus un GLB. Le GLB possède une arête visible, mais aucun ID de pli ni relevé d'adjacence des panneaux. Un réviseur peut-il vérifier que `e1` a changé d'état et représente toujours la dépendance de politique ?

> **Réponse :** Non. Les images peuvent étayer une différence visuelle, mais n'identifient ni l'arête `e1`, ni les panneaux qu'elle joint, ni l'état de politique qu'elle signifie. Ajoutez un manifeste externe versionné avec ID de panneaux et de plis, adjacence, convention d'angles signés, correspondance état-sens et empreintes du GLB et de la scène. Testez ensuite la correspondance après import par une sélection ou un changement d'état intentionnel. Une arête seule n'est pas une preuve sémantique.

## 2. Distinguer les preuves géométriques, matérielles et sémantiques

La **géométrie** comprend sommets, faces, adjacence des panneaux, silhouette, épaisseur, normales et pose mesurée. Le [script de modélisation](https://github.com/spareilleux/learn/blob/93d424f872a576ba8bbcd3dd44c9733292373654/code/blender/scripts/l02_modeling.py) Learn figé construit un plan ouvert à un quadrilatère et un exemple à trois quadrilatères partageant une arête ; son [rapport versionné](https://github.com/spareilleux/learn/blob/93d424f872a576ba8bbcd3dd44c9733292373654/code/blender/expected/l02_modeling.txt) relève les arêtes de bord et non-manifold. Ces exemples montrent comment examiner la topologie, pas qu'un asset plié particulier est valide. Une feuille possède intentionnellement des arêtes de bord ; en exiger zéro la rejetterait à tort. À l'inverse, une charnière non-manifold ou une face dupliquée déconnectée exige une enquête même si un rendu unique paraît lisse.

Le **matériau** comprend couleur de base, texture, disposition UV, rugosité et ombrage. Le [script de matériau et glTF](https://github.com/spareilleux/learn/blob/93d424f872a576ba8bbcd3dd44c9733292373654/code/blender/scripts/l03_materials.py) Learn figé et son [rapport de référence](https://github.com/spareilleux/learn/blob/93d424f872a576ba8bbcd3dd44c9733292373654/code/blender/expected/l03_materials.txt) montrent des coordonnées UV aux coins des faces et examinent attributs de maillage et valeurs de matériau d'un glTF exporté. Ils ne testent pas notre panneau plié proposé. Un trait foncé peint peut signaler visuellement un pli alors que la géométrie reste plate ; une arête géométrique peut rester après perte de texture ou d'UV. Capturez ces éléments comme des observations distinctes.

La **sémantique du pli** comprend `e1` et `e2`, l'ordre des panneaux, l'état montagne/vallée selon la convention déclarée, les transitions autorisées et le sens de gouvernance attribué. Un rendu GLB ou un nombre de triangles ne les établit pas. Stockez la sémantique dans un fichier annexe d'essai, puis vérifiez que la scène Godot relie les bons ID d'objets à la bonne transition. Ce fichier annexe est une fixture proposée, pas un schéma ou format de déploiement implémenté.

### Exercice 2 : classer trois observations

Dans un import hypothétique, (a) la silhouette se plie à l'endroit attendu, (b) un trait bleu marque le pli mais disparaît après un changement de matériau et (c) cliquer l'objet `e1` rendu produit l'étiquette de politique `e2`. Quelle couche chaque observation teste-t-elle et laquelle fait échouer l'essai ?

> **Réponse :** (a) est une preuve géométrique, sans prouver seule l'identité du pli. (b) est une preuve matérielle ; sa disparition montre la vulnérabilité de l'indice visuel à un changement de matériau. (c) teste le rattachement sémantique de la scène et échoue, car `e1` sélectionne l'étiquette `e2`. Corrigez la correspondance des ID et répétez la trace d'interaction ; réparer seulement le shader ne corrigerait pas cette erreur.

## 3. Rendre la pose mesurable sans confondre angle et sens

Pour un essai, consignez la transformation source de chaque panneau et les deux poses de charnière dans Blender, exportez un état figé à la fois et inscrivez l'angle signé prévu dans le manifeste externe. Un angle se calcule à partir de normales de panneaux orientées de façon cohérente autour d'un pli orienté ; sans cette orientation, ce n'est qu'une amplitude de courbure non signée. Définissez une cible synthétique de `+60°` pour `e1` et `−60°` pour `e2` dans `closed`, et une pose à `±5°` près de la position plate pour chacun dans `open`. Ce sont des tolérances pédagogiques, pas un comportement Godot mesuré ni une norme de pliage du papier. Le manifeste devrait aussi consigner échelle d'unités, réglages d'export, convention de coordonnées et noms des objets panneaux/plis. Si un export applique des transformations ou change la convention d'axes, l'adaptateur de scène doit préserver explicitement la correspondance des signes.

Avant l'animation, comparez des instantanés statiques. Importez les GLB source et candidat dans la même scène Godot versionnée, avec les mêmes échelle et caméra. Conservez journaux d'import, correspondance des noms, captures brutes en panneau et plein écran, et trace d'interaction pour les deux états. Examinez l'avant et l'arrière : un trait seulement matériel peut disparaître au dos, et un pli peut cacher un panneau à une caméra. Un futur test d'animation exigerait des états intermédiaires et des contrôles d'auto-intersection ; deux extrémités ne certifient pas un mouvement de pliage physiquement réalisable.

### Exercice 3 : évaluer une pose synthétique

Selon la convention de signe déclarée, un import candidat `closed` mesure `e1 = +58°` et `e2 = +61°`. La tolérance est de cinq degrés autour de chaque cible. Quelle charnière réussit et pourquoi une capture nette ne suffit-elle pas à approuver l'état ?

> **Réponse :** `e1` réussit, car `|58 − 60| = 2°`. `e2` échoue, car `|61 − (−60)| = 121°` ; l'amplitude ressemble à la cible, mais le signe est inversé. Vérifiez l'ordre des sommets des faces et la correspondance de scène avant de décider si la géométrie ou la convention de mesure est en cause. Une capture d'un seul côté peut masquer l'erreur de signe et ne dit rien de l'étiquette de politique `e2`.

## 4. Comparer une caractéristique à la fois dans l'observatoire

Établissez une référence utilisant un panneau plat statique et un simple libellé textuel d'état. C'est une interface plus simple, qui peut s'avérer plus claire qu'une forme pliée. Le candidat plié ne mérite sa place que si les utilisateurs identifient les deux états et la dépendance prévue avec une fiabilité au moins égale pour la même tâche, en restant dans un coût de scène convenu. Gardez fixes l'instantané de données de gouvernance, les libellés, le viewport, le moteur de rendu, l'éclairage, la caméra, le build et la séquence d'entrées. Pour comparer la géométrie, changez le maillage de pli en gardant les indices matériels fixes. Pour comparer le matériau, utilisez le même maillage et la même pose en changeant l'indice de pli. Pour le rattachement sémantique, injectez la même transition nommée et examinez l'ID de pli sélectionné et l'étiquette de politique résultante. Ne traitez pas une capture combinée comme preuve des trois couches.

Utilisez comme contrôles les captures brutes répétées et la trace de clics proposées par VC-004. Déclarez l'essai à l'avance : trois captures répétées de chaque état en panneau et plein écran ; aucun ID d'objet manquant ; aucune erreur d'import ; angles dans la tolérance ; clics intentionnels sur `e1` et `e2` dans chaque pose produisant l'ID, l'état et l'étiquette déclarés du pli dans chaque trace. Pour une première tâche de compréhension, demandez à quatre réviseurs de choisir `open` ou `closed` et de nommer la dépendance sans réponses superposées. Exigez au moins le nombre de réponses correctes de la référence textuelle plate, pas un pourcentage universel tiré de quatre personnes. Gardez les réponses individuelles et les erreurs. Consignez nombre de triangles et distribution des temps par image sur le même appareil, mais choisissez un plafond de coût à partir d'une vraie mesure de référence avant d'en faire une condition d'acceptation. Aucune mesure de cet essai proposé n'a été réalisée pour cette leçon.

### Exercice 4 : isoler la cause

Le candidat X utilise un nouveau maillage plié, une nouvelle texture bleue de pli, une nouvelle caméra et un libellé de politique modifié. Quatre réviseurs identifient son état `closed`. La référence textuelle plate obtient trois bonnes réponses. Cela établit-il que la géométrie pliée améliore la compréhension ? Concevez la prochaine comparaison.

> **Réponse :** Non. Géométrie, matériau, caméra et formulation ont changé ensemble, et quatre observations sont trop peu nombreuses pour une affirmation générale. Restaurez la caméra et le libellé de référence, gardez le matériau du pli fixe et comparez les géométries plate et pliée avec la même tâche. Faites ensuite varier l'indice matériel à géométrie fixe. Stockez réponses par réviseur et captures brutes ; ne rapportez le petit essai comme résultat local que s'il est réellement exécuté.

## 5. Décider si le pli appartient à un langage de scène composable

L'implémentation viable la plus simple est un asset Blender, un petit manifeste externe et une correspondance explicite d'ID d'objets Godot révisée à partir des captures brutes et clics. Une future description de scène composable pourrait déclarer `panel`, `crease`, `adjacent_to`, `signed_pose`, `state` et `meaning`. Il ne faut pas l'adopter au seul motif que ces mots se composent sur le papier. Le contre-argument le plus fort est qu'un panneau plat avec texte transmet le même état de gouvernance avec moins de modélisation, d'import, de travail d'accessibilité et de maintenance. Les coûts cachés comprennent création et validation des ID stables, préservation du signe lors des conversions de coordonnées, entretien des indices avant/arrière et traduction des libellés indépendamment de la géométrie. Un langage proposé devrait réduire les erreurs observées ou le temps de révision par rapport au manifeste et à la checklist.

**N'acceptez le candidat d'essai** qu'après un import Godot versionné et des preuves brutes montrant des ID et rattachements corrects, des angles dans la tolérance, aucun panneau manquant, une compréhension au moins égale à la référence et un coût mesuré dans un budget prédéclaré. **Rejetez-le ou révisez-le** si une inversion de signe ou une mauvaise étiquette passe l'examen visuel, si la compréhension est inférieure à la référence, si la correspondance des ID ne peut être rejouée ou si le coût dépasse le plafond convenu. Si aucune scène ou export n'est disponible, marquez le candidat **non évalué**, pas accepté. Un DSL d'états de pli reste une hypothèse consultative tant qu'une comparaison contrôlée ne surpasse pas le simple manifeste.

### Exercice 5 : appliquer la règle de décision

Supposons qu'un futur candidat possède empreintes et captures complètes, des angles de `+60°` et `−59°` et un temps par image mesuré acceptable. Trois réviseurs sur quatre identifient la dépendance, contre quatre sur quatre avec le texte plat. Son clic `e1` renvoie aussi l'étiquette `e2` une fois sur dix rejeux. Quelle décision en découle et quelles preuves sont nécessaires ?

> **Réponse :** Rejetez ou révisez ce candidat selon la règle déclarée. Les contrôles d'angle et de coût réussissent, mais la compréhension est inférieure à la référence et le rattachement `e1` est erroné lors d'un rejeu. Conservez les empreintes GLB source et sortie, la révision de scène, le manifeste annexe, les journaux d'import, les captures brutes, les dix traces d'événements, les réponses individuelles et les échantillons de temps par image. Corrigez le rattachement et l'explication visuelle, puis répétez la même comparaison. Les chiffres inventés sont une fixture d'exercice, pas une mesure du projet.

## Preuves et limites

- Le plan et l'hôte GA liés établissent un chemin de visualisation proposé ; ils n'établissent pas un observatoire plié en fonctionnement. Les scripts et rapports Learn liés établissent des exemples de modélisation, topologie, UV et glTF sur d'autres assets ; ils ne valident pas cette fixture.
- Tous les angles, nombres de réviseurs, résultats de scène et sens de politique des exercices sont synthétiques. Aucune exécution Blender ou Godot, analyse culturelle, révision humaine, tentative d'apprenant ou consultation publique n'est revendiquée. Le cycle source anglais antérieur ne revendiquait pas non plus de traduction ; ce brouillon français attend l'approbation d'une personne maîtrisant le français.
- Le seuil de nettoyage de VC-005 peut compter ultérieurement, mais préserver les triangles seuls ne préserve pas l'ID, le signe et le sens d'un pli. Ce cours distingue ces vérifications.
