---
title: Vérifier les unités d’une scène de tissage
description: Vérifier les unités d’une scène de tissage — Physique
sidebar:
  label: PHY-006 · Vérifier les unités d’une scène de tissage
  order: 6
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/physics/fr/phy-006-check-weave-scene-units.fr.md
---

:::note[Streeling University]
**PHY-006** · Vérifier les unités d’une scène de tissage · intermédiaire · 45 minutes

Généré par le département *Physique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/physics/fr/phy-006-check-weave-scene-units.fr.md) · [Mon journal](../../journal/)

Prérequis: [PHY-005](../../physics/phy-005-sheet-thickness-and-scene-units/)
:::

> **Brouillon source rédigé par IA.** Les validations humaines par un spécialiste du domaine, un réviseur maîtrisant la langue et un apprenant restent à réaliser. La publication HTML publique du cours reste en attente.

[PHY-005](../../physics/phy-005-sheet-thickness-and-scene-units/) exige une échelle déclarée. Cet adaptateur [Godot](https://docs.godotengine.org/en/4.6/tutorials/editor/command_line_tutorial.html) l’applique à des représentations de tissage enregistrées. Votre livrable est un audit capable de rejeter une scène mal dimensionnée. Consultez le [README du laboratoire](https://github.com/spareilleux/learn/blob/main/code/streeling/weave-godot/README.md), le [README des preuves](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/weave-scene-2026-10-22/README.md) et la [tâche de l’apprenant](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/weave-scene-2026-10-22/learner-task.md). Le README des preuves conserve les détails des exécutions et les échecs.

Résultat vérifié sous Windows : l’enregistrement, le chargement et les 36 sondes physiques ont réussi ; les contrôles d’échelle, de liaison du corps de collision et de parité redémarrée ont échoué aux vérifications nommées. Les anciens échecs du lanceur n’apportent aucune preuve sur la scène.

## 1. Déclarer l’interprétation physique

L’[évaluateur](https://raw.githubusercontent.com/GuitarAlchemist/Demerzel/f23ccae6c049d9066a1be2221c68f3b0bcf48373/state/streeling/fixtures/visual-computing/vc-007/evaluate_weave.py) et la [spécification](https://raw.githubusercontent.com/GuitarAlchemist/Demerzel/f23ccae6c049d9066a1be2221c68f3b0bcf48373/state/streeling/fixtures/visual-computing/vc-007/weave-trial.json), figés à une révision précise, définissent `odd-tile-seam-a` : pas de 5 mm et diamètre nominal de 2 mm. Un motif de 3 × 3 répété 2 × 2 donne 6 × 6 croisements. La parité globale produit 0 violation d’adjacence ; la parité redémarrée en produit 12 et doit être refusée avant la construction de la scène.

L’adaptateur choisit une unité de scène par mètre et représente le diamètre par une épaisseur de boîte. La chaîne suit Z et la trame X. Les croisements contiennent des segments isolés. Cette interprétation constitue une entrée déclarée, pas une mesure textile.

### Exercice 1 — Lire l’échelle

Convertissez le pas de 5 mm et l’épaisseur de 2 mm dans la convention de scène. Calculez le rapport épaisseur sur pas.

> **Réponse :** Le pas vaut `5 × 0.001 = 0.005 m` ; l’épaisseur vaut `2 × 0.001 = 0.002 m`. Leur rapport sans dimension est `2/5 = 0.4`. Il doit être conservé par une mise à l’échelle uniforme cohérente, mais ne permet pas à lui seul de déterminer l’échelle absolue de la scène.

## 2. Vérifier séparément les positions et les dimensions

Les indices de croisement vont de 0 à 5. `w3-f0` se trouve donc à X `3 × 0.005 = 0.015 m`, et la dernière coordonnée vaut `5 × 0.005 = 0.025 m`. Six centres de croisement délimitent cinq intervalles. Donner 0.030 m comme distance entre les centres extrêmes confond un nombre d’objets avec un nombre d’intervalles.

Les dimensions `(X,Y,Z)` de la boîte de chaîne sont `(0.002,0.002,0.004) m` ; celles de la trame sont `(0.004,0.002,0.002) m`. Leurs axes longs différents expriment les directions des brins. Des vérifications de position seules ne détecteraient ni une longueur erronée ni des axes permutés. Les limites de [MeshInstance3D](https://docs.godotengine.org/en/4.6/classes/class_meshinstance3d.html) après chargement fournissent une observation distincte de la taille.

### Exercice 2 — Diagnostiquer deux erreurs

Une scène place `w3-f0` à X 15 et donne aux deux boîtes les dimensions `(0.004,0.002,0.002)`. Repérez les erreurs indépendantes.

> **Réponse :** X 15 vaut 1000 fois les 0.015 requis dans la convention métrique. L’axe long de la chaîne est également incorrect : il doit suivre Z avec `(0.002,0.002,0.004)`. Corriger la position ne corrige ni les dimensions ni la convention d’orientation.

## 3. Calculer l’écart vertical

Les centres des boîtes supérieure et inférieure se trouvent à Y `+0.0015 m` et `-0.0015 m`. Leur épaisseur est de 0.002 m, donc chaque demi-épaisseur vaut 0.001 m. Le bas de la boîte supérieure est à `0.0015 - 0.001 = 0.0005 m` ; le haut de l’inférieure est à `-0.0015 + 0.001 = -0.0005 m`. La différence vaut `0.001 m`, soit 1 mm.

L’essai compare les limites [AABB](https://docs.godotengine.org/en/4.6/classes/class_aabb.html) transformées après chargement. Ces boîtes sans rotation, alignées sur les axes, rendent l’écart vertical vérifiable. Ce calcul n’établit ni dégagement de fabrication, ni contact de cylindres, ni flexion, ni chemin reliant les segments. Une géométrie tournée ou courbe exige un autre raisonnement.

### Exercice 3 — Distinguer écart et centres

Quelqu’un annonce un dégagement de 3 mm parce que les centres sont séparés de 3 mm. Corrigez le calcul.

> **Réponse :** Soustrayez les deux demi-épaisseurs à la distance entre centres : `3 - 1 - 1 = 1 mm`. La distance entre centres n’est pas le dégagement entre surfaces. Le résultat concerne les boîtes déclarées, sans rotation, pas un textile réel.

## 4. Utiliser un contrôle d’échelle indépendant

Si le vérificateur multiplie les valeurs attendues par le `MM_TO_M` du constructeur, modifier cette constante peut déplacer simultanément construction et attentes. Le laboratoire utilise donc des attentes en mètres écrites indépendamment. Dans une copie temporaire, changez uniquement le `MM_TO_M` du constructeur de `0.001` à `1`. La vérification nommée `independent_world_metres` doit rejeter le résultat ; des rapports inchangés ne détectent pas ce facteur uniforme de 1000.

Avec [Node.js](https://nodejs.org/en/learn/getting-started/introduction-to-nodejs), [Python](https://docs.python.org/3/using/cmdline.html) et Godot 4.6.1 installés et accessibles dans `PATH`, utilisez un nouveau répertoire de sortie hors du checkout :

```text
node code/streeling/weave-godot/run.mjs NEW_OUTPUT_DIR EXTERNAL_EVALUATOR.py EXTERNAL_SPEC.json
```

La commande s’écrit de la même façon sur chaque système. Windows a été essayé ; Linux/WSL et macOS restent à vérifier. Conservez les empreintes des sources originales et modifiées, les rapports réels et les journaux. Un échec de démarrage se distingue d’un prédicat métrique faux et n’apporte aucune nouvelle preuve sur la scène.

### Exercice 4 — Éprouver le vérificateur

Tous les rapports restent à 0.4 après la modification. Cela invalide-t-il le contrôle négatif ?

> **Réponse :** Non. Les rapports sont volontairement insensibles à une échelle uniforme. L’attente absolue indépendante X 0.015 m à `w3-f0`, avec les contrôles d’épaisseur et de centres, doit échouer. Si l’exécution modifiée ne démarre pas, le résultat visé par le contrôle reste non évalué.

## 5. Transmettre seulement la conclusion étayée

Observez, changez une grandeur, relancez, conservez l’échec et précisez sa portée. Un audit réussi étayerait les coordonnées rechargées et les limites des boîtes pour ces octets source. Il ne fournit aucune propriété matérielle mesurée. Vérifiez l’état d’exécution dans le README des preuves avant d’annoncer une réussite.

Composer validation sémantique, sérialisation et vérification dimensionnelle constitue une hypothèse sur l’utilité du processus d’inspection. La référence 2D étiquetée, moins coûteuse, peut montrer la même échelle et la même parité. Affirmer un meilleur apprentissage exige une comparaison distincte des tâches, avec erreurs sans aide et effort fourni.

### Exercice 5 — Rédiger une transmission honnête

Formulez une conclusion en deux phrases lorsque les prédicats géométriques réussissent sans essai auprès d’apprenants ni essai matériel.

> **Réponse :** « Pour le manifeste figé et la convention métrique déclarée, les boîtes isolées rechargées respectent les positions, dimensions et l’écart vertical AABB de 0.001 m consignés. Cela n’établit ni comportement d’un fil continu, ni dégagement de fabrication, ni intérêt pédagogique, ni validation achevée du domaine et de la langue. » Joignez le compte rendu réel et employez le conditionnel si l’exécution reste en attente.
