---
title: Enregistrer une scène de tissage et l’interroger
description: Enregistrer une scène de tissage et l’interroger — Informatique visuelle
sidebar:
  label: VC-008 · Enregistrer une scène de tissage et l’interroger
  order: 8
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/visual-computing/fr/vc-008-save-and-query-a-weave-scene.fr.md
---

:::note[Streeling University]
**VC-008** · Enregistrer une scène de tissage et l’interroger · intermédiaire · 45 minutes

Généré par le département *Informatique visuelle* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/visual-computing/fr/vc-008-save-and-query-a-weave-scene.fr.md) · [Mon journal](../../journal/)

Prérequis: [VC-007](../../visual-computing/vc-007-weave-seams-as-scene-contracts/)
:::

> **Brouillon source rédigé par IA.** Les validations humaines par un spécialiste du domaine, un réviseur maîtrisant la langue et un apprenant restent à réaliser. La publication HTML publique du cours reste en attente.

[VC-007](../../visual-computing/vc-007-weave-seams-as-scene-contracts/) vérifie un tissage synthétique avant son rendu. Ce cours demande si les croisements admis survivent à l’enregistrement puis au chargement natif d’une scène [Godot](https://docs.godotengine.org/en/4.6/tutorials/editor/command_line_tutorial.html), tout en restant interrogeables. Votre livrable est un compte rendu identifiant l’artefact enregistré, les observations après chargement et les limites de la conclusion. Consultez le [README du laboratoire](https://github.com/spareilleux/learn/blob/main/code/streeling/weave-godot/README.md), le [README des preuves](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/weave-scene-2026-10-22/README.md) et la [tâche de l’apprenant](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/weave-scene-2026-10-22/learner-task.md). Le README des preuves conserve les détails des exécutions et les échecs.

Résultat vérifié sous Windows : l’enregistrement, le chargement et les 36 sondes physiques ont réussi ; les contrôles d’échelle, de liaison du corps de collision et de parité redémarrée ont échoué aux vérifications nommées. Les anciens échecs du lanceur n’apportent aucune preuve sur la scène.

## 1. Admettre un modèle déclaré

L’[évaluateur](https://raw.githubusercontent.com/GuitarAlchemist/Demerzel/f23ccae6c049d9066a1be2221c68f3b0bcf48373/state/streeling/fixtures/visual-computing/vc-007/evaluate_weave.py) et la [spécification](https://raw.githubusercontent.com/GuitarAlchemist/Demerzel/f23ccae6c049d9066a1be2221c68f3b0bcf48373/state/streeling/fixtures/visual-computing/vc-007/weave-trial.json), figés et immuables, décrivent `odd-tile-seam-a` : un motif de 3 × 3 répété 2 × 2 donne 6 × 6, soit 36 croisements. La parité globale produit 0 violation d’adjacence ; la parité redémarrée dans chaque motif en produit 12. L’admission rejette cette dernière avant la création de la scène. Une apparence plausible ne corrige pas cet échec sémantique.

L’adaptateur crée deux segments de boîte isolés par croisement. La chaîne suit l’axe Z du monde et la trame l’axe X. Le diamètre nominal de 2 mm devient une épaisseur de boîte, sans modéliser un fil cylindrique. Ces segments n’établissent ni continuité du fil, ni tension, ni contact textile. Ce petit modèle rend le transfert vérifiable sans prétendre fournir un exportateur général.

### Exercice 1 — Situer la frontière

La variante redémarrée produit 12 violations, mais pourrait donner une belle image. Faut-il construire sa scène ?

> **Réponse :** Non. `semantic_admission` doit la rejeter avant la création d’un projet Godot. Conservez le rapport sémantique et l’échec ; l’attrait visuel ne prouve pas que l’alternance déclarée a survécu à la composition.

## 2. Rendre la persistance observable

Un arbre de nœuds vivant ne suffit pas à prouver le contenu d’une scène enregistrée. [PackedScene](https://docs.godotengine.org/en/4.6/classes/class_packedscene.html) regroupe des nœuds pour leur instanciation ; l’adaptateur attribue des propriétaires aux croisements, maillages, corps et formes de collision afin d’inclure les descendants voulus. Il ajoute les métadonnées de croisement et de brin ainsi que l’empreinte du manifeste source. Sans propriétaires, des descendants peuvent disparaître malgré un arbre initial complet.

L’essai regroupe la racine, enregistre `weave.tscn`, libère l’arbre initial, recharge les octets enregistrés, instancie un nouvel arbre et attend la synchronisation physique. Les observations portent alors sur l’instance rechargée. Les effectifs attendus sont 36 parents de croisement et 72 maillages, corps statiques et formes de collision de chaque catégorie. Deux ressources partagées par catégorie de maillage, forme et matériau évitent 72 copies distinctes ; le partage des ressources se distingue du nombre d’instances.

### Exercice 2 — Contester une preuve d’enregistrement

Un rapport compte 72 maillages avant l’enregistrement et ne libère jamais l’original. Quelle observation manque ?

> **Réponse :** Supprimez l’original, chargez puis instanciez l’artefact enregistré, comptez ses descendants et inspectez leurs métadonnées. Un appel d’enregistrement réussi et un arbre initial complet ne prouvent pas que les propriétaires ont permis de conserver les descendants requis.

## 3. Interroger la représentation rechargée

Chaque [MeshInstance3D](https://docs.godotengine.org/en/4.6/classes/class_meshinstance3d.html) affiche une représentation simplifiée ; un corps statique et une forme de collision la rendent interrogeable. Après chargement, [PhysicsDirectSpaceState3D.intersect_ray](https://docs.godotengine.org/en/4.6/classes/class_physicsdirectspacestate3d.html) lance 36 rayons descendants à travers les centres attendus, définis indépendamment. Les métadonnées du corps touché doivent désigner le croisement demandé et son brin supérieur attendu. À `w2-f0`, la chaîne est au-dessus ; à `w3-f0`, c’est la trame.

Il s’agit de sondes physiques automatisées. Elles n’établissent ni la justesse d’une sélection humaine ni la visibilité dans un rendu. Cette tâche n’utilise ni caméra, ni surbrillance, ni capture d’écran. Une position de maillage correcte ne prouve pas non plus que le corps de collision renvoie au bon ID source.

### Exercice 3 — Interpréter un résultat

Un rayon visant `w3-f0` touche la géométrie de trame, mais indique `w2-f0`. Quelle exigence échoue ?

> **Réponse :** `ray_crossing_identity` échoue même si `ray_upper_strand` et les vérifications géométriques réussissent. La scène désigne le mauvais croisement source. Conservez les deux résultats au lieu de les résumer par « le rayon a touché quelque chose ».

## 4. Reproduire avec la provenance

Avec [Node.js](https://nodejs.org/en/learn/getting-started/introduction-to-nodejs), [Python](https://docs.python.org/3/using/cmdline.html) et Godot 4.6.1 installés et accessibles dans `PATH`, lancez depuis la racine du dépôt :

```text
node code/streeling/weave-godot/run.mjs NEW_OUTPUT_DIR EXTERNAL_EVALUATOR.py EXTERNAL_SPEC.json
```

Choisissez un nouveau répertoire de sortie hors du checkout et des entrées externes inchangées. Le programme conserve les empreintes SHA-256 des entrées et fichiers pédagogiques, l’empreinte du manifeste, les journaux et les rapports ; le rapport Godot conserve celle de la scène. Comparez les octets à leur provenance, pas seulement les noms de fichiers. La commande est identique sur les différents systèmes ; seul Windows a été essayé, Linux/WSL et macOS restent à vérifier.

### Exercice 4 — Distinguer les échecs

Godot dépasse le délai de démarrage après l’admission sémantique. Le résultat sémantique certifie-t-il la nouvelle scène ?

> **Réponse :** Non. Conservez les journaux de démarrage et le rapport d’exécution en échec. Un problème d’environnement ou d’exécution se distingue d’un rejet sémantique, mais n’apporte aucune nouvelle preuve d’enregistrement, de chargement ou de physique. Réessayez dans un nouveau répertoire et rapportez le résultat réel.

## 5. Conserver un contre-exemple utile

Observez la référence, changez une seule hypothèse, relancez, conservez l’échec et bornez la conclusion. Dans une copie temporaire, modifier uniquement `crossing_id` du corps de collision doit faire échouer l’identité ; modifier uniquement `MM_TO_M` du constructeur doit faire échouer les attentes indépendantes en mètres. Aucun de ces contrôles ne prouve à lui seul l’intérêt pédagogique. Consultez le README des preuves avant de les décrire comme exécutés.

La composabilité est une hypothèse testée à cette frontière. Connecter davantage d’outils n’accélère pas automatiquement les progrès. Comparez toute explication 3D envisagée à l’alternative moins coûteuse : évaluateur et grille 2D étiquetée, avec la même tâche d’apprentissage. Recueillez les réponses sans aide et l’effort de maintenance avant d’affirmer un avantage ou de proposer un DSL.

### Exercice 5 — Formuler la conclusion de livraison

Que permet de conclure un aller-retour entièrement réussi, et quelle preuve supplémentaire justifierait de le préférer à la 2D ?

> **Réponse :** Il étaye la persistance et la justesse des requêtes scriptées pour ces entrées figées et ces représentations isolées. Une comparaison contrôlée auprès d’apprenants reste nécessaire pour établir une préférence pédagogique. Les validations du domaine, de la langue, de l’apprentissage et de la publication restent en attente ; une réussite technique ne démontre ni simulation textile, ni intégration produit, ni interaction humaine.
