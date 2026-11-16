---
title: Préserver les détails artisanaux lors d'un essai d'asset Blender-vers-Godot
description: Préserver les détails artisanaux lors d’un essai d’asset Blender-vers-Godot — Informatique visuelle
sidebar:
  label: VC-005 · Préserver les détails artisanaux lors d'un essai d'asset Blender-vers-Godot
  order: 5
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/visual-computing/fr/vc-005-craft-details-through-blender-to-godot.fr.md
---

:::note[Streeling University]
**VC-005** · Préserver les détails artisanaux lors d’un essai d’asset Blender-vers-Godot · intermédiaire · 40 minutes

Généré par le département *Informatique visuelle* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/visual-computing/fr/vc-005-craft-details-through-blender-to-godot.fr.md) · [Mon journal](../../journal/)

Prérequis: [VC-004](../../visual-computing/vc-004-godot-observatory-capture-gate/)
:::

> **Périmètre du brouillon et des traductions.** Le texte technique ci-dessous est un brouillon daté. Les mentions historiques de traductions, d’intégration dans Learn ou de vérifications de publication encore à faire concernent cette étape antérieure ; ce [dossier de traduction](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/locale-completion-2026-10-22/README.md) recense les brouillons actuels et les contrôles effectués. Les essais en conditions réelles encore non réalisés le restent. Les revues humaines du contenu et de la langue, ainsi que l’essai avec un apprenant, restent à effectuer.

> **Département d'informatique visuelle** | Intermédiaire | 40 minutes | Brouillon français ; aucun import Godot, révision humaine, essai d'apprenant ou publication ; approbation par une personne maîtrisant le français en attente

## Objectifs et question du projet

Après cette leçon, vous saurez distinguer un détail artisanal d'un bruit de maillage supprimable, prévoir deux pertes de nettoyage d'un pipeline Blender figé, concevoir une comparaison réversible d'assets pour un observatoire Godot et définir les preuves qui feraient rejeter une règle de nettoyage automatisée. **Question du projet :** si un nœud tissé, une arête de papier plié ou une marque de métal ciselé porte un sens dans un objet de gouvernance, un pipeline de nettoyage peut-il réduire le coût de l'asset sans effacer ce sens ? C'est une conception d'essai d'asset, pas une affirmation que ces éléments artisanaux ou la scène Godot sont déjà implémentés.

## 1. Partir d'un vrai pipeline et d'une scène proposée

Le [script de nettoyage GLB](https://github.com/spareilleux/learn/blob/93d424f872a576ba8bbcd3dd44c9733292373654/code/blender/scripts/glb_pipeline.py) Learn figé importe un `.glb`, joint les objets de maillage, fusionne les sommets voisins, supprime les parties connexes sous un seuil de fraction des faces, recalcule les normales, remaille éventuellement par voxels, décime vers un budget de triangles, exporte un `.glb` nettoyé, puis le réimporte pour un rapport. Sa docstring cible three.js. Le [vérificateur d'exemple](https://github.com/spareilleux/learn/blob/93d424f872a576ba8bbcd3dd44c9733292373654/code/blender/scripts/pipeline_check.py) construit un maillage défectueux de médiator et exécute le pipeline deux fois, dont une avec remaillage par voxels. Son [rapport attendu](https://github.com/spareilleux/learn/blob/93d424f872a576ba8bbcd3dd44c9733292373654/code/blender/expected/pipeline_check.txt) est un résultat de référence versionné, pas une nouvelle exécution pour cette leçon.

La [leçon de capture VC-004](../../visual-computing/vc-004-godot-observatory-capture-gate/) précédente définit une condition proposée d'image et d'interaction pour l'observatoire Godot. Ce cours demande si une géométrie issue de techniques artisanales pourrait devenir un asset versionné de cette future scène. Le script Learn ne prouve pas la compatibilité Godot. Import Godot, capture de scène et comparaison de tâches restent des expériences distinctes.

### Exercice 1 : nommer la limite des preuves

Un collègue dit : « Le rapport de nettoyage Learn prouve que notre nœud tissé est sûr dans Godot. » Quelle partie est étayée et que manque-t-il ?

> **Réponse :** La source et le rapport attendu montrent qu'un exemple de maillage de médiator peut être traité selon des réglages Blender déclarés. Ils ne contiennent ni asset de nœud tissé ni import Godot. Pour tester l'affirmation, versionnez le `.glb` candidat, consignez source et réglages, importez-le dans une scène Godot versionnée, capturez les vues prévues et effectuez une tâche de reconnaissance du détail face à une référence. Le rapport versionné seul ne certifie pas qu'un nœud reste reconnaissable.

## 2. Modéliser un détail avant de le simplifier

Un détail artisanal doit avoir un **rôle** déclaré. Pour un nœud de gouvernance tissé hypothétique, un petit nœud pourrait indiquer une limite d'autorité ; pour un panneau origami, une arête de pli distinguerait un état ouvert d'un état fermé ; pour du métal ciselé, une marque peu profonde identifierait matériau ou provenance. Traitez-les comme des caractéristiques sémantiques candidates, pas comme de la décoration par défaut. Donnez à chacune un ID, un sens court, la région de maillage ou le matériau occupé et une vue où un apprenant devrait l'identifier. Gardez ce manifeste hors du script actuel : sa jonction d'objets et son nettoyage de parties connexes ne portent pas un tel contrat d'approbation.

La valeur par défaut de `--min-part` est `0.01` : une partie connexe comptant **moins** d'un pour cent de toutes les faces est supprimée. Dans le rapport attendu figé, le modèle importé possède 5,140 faces et le nettoyage supprime une partie de 20 faces. C'est raisonnable pour l'amas volontairement flottant du vérificateur, mais ce serait une perte sémantique si cette partie de 20 faces était un nœud intentionnel. Le seuil est une règle topologique, pas un test de sens artisanal. Qualifier un élément d'« important » en prose ne change pas le code actuel.

### Exercice 2 : appliquer la comparaison réelle

Prenez un asset **synthétique** de 5,140 faces avec un nœud d'autorité isolé de 20 faces. À `--min-part 0.01`, est-il supprimé ? Quelle est la première comparaison la moins risquée ?

> **Réponse :** Un pour cent vaut 51.4 faces et `20 < 51.4` ; la règle actuelle supprimerait donc cette partie connexe. Comparez l'export source inchangé à un nettoyage avec `--min-part 0.001` : le seuil devient 5.14 faces, donc une composante isolée de 20 faces est conservée par cette règle. Gardez les autres réglages fixes et vérifiez rapports de maillage et vue rendue du nœud. Conserver de petites parties peut conserver du bruit ; c'est un diagnostic, pas une politique finale. Le chemin `--min-part 0` du script figé renvoie une liste vide là où l'appelant attend une paire ; zéro n'est donc pas un contournement valide à cette révision. La [correction proposée à Learn `deac6e1`](https://github.com/spareilleux/learn/blob/deac6e12a64864703300e5645cd5a9d1d374e062/code/blender/scripts/glb_pipeline.py) renvoie une paire sur ce chemin de retour anticipé. La PR #168 a été observée ouverte et en brouillon pendant cette passe de traduction ; elle n’est pas fusionnée. Un appel limité au code source confirme la paire ; une exécution Blender reste non vérifiée. Si le nœud touche une plus grande composante, cette règle particulière peut ne pas le supprimer ; la reconnaissance peut encore échouer après décimation ou changement d'ombrage.

## 3. Distinguer géométrie, matériau et sens

Le rapport attendu donne un second avertissement. Sur le chemin sans remaillage, l'échantillon nettoyé possède une couche UV et zéro arête de bord avant export ; après export et réimport, il rapporte 186 arêtes de bord, puis zéro après fusion des sommets par position. Le commentaire explique que glTF peut scinder un sommet aux coutures de normales ou d'UV. Un décompte brut d'arêtes de bord après réimport ne prouve donc pas à lui seul un trou physique. Conservez rapports bruts et après fusion par position et examinez la surface rendue là où une couture compte. L'exemple ne dit rien de la lisibilité persistante du sens des fils d'un motif tissé ou d'une finition métallique.

Dans le chemin de remaillage par voxels, le rapport attendu passe d'une couche UV avant nettoyage à `none` après. Cela peut convenir à de la simple géométrie, mais on ne peut supposer la survie d'un motif porté par une texture UV. Un nom de matériau différent dans le rapport ne serait aussi qu'un signal structurel ; éclairage, direction des normales, espace colorimétrique et distance de vue affectent la perception. Un maillage fermé manifold peut encore communiquer le mauvais détail artisanal.

### Exercice 3 : lire le rapport sans exagérer

Après réimport, un modèle rapporte 186 arêtes de bord ; après fusion par position, zéro. Cela établit-il seul un maillage endommagé ? La variante remesh par voxels rapporte `uv: none` ; qu'en déduire pour un motif tissé encodé en UV ?

> **Réponse :** Non. Les sommets scindés aux coutures d'export peuvent produire le premier décompte, et le second s'oppose à l'interprétation d'un trou démontré. Examinez source et couture rendue avant de décider. `uv: none` montre que le chemin testé n'a pas préservé de couche UV dans l'échantillon de référence. Un motif qui en dépend nécessite une étape distincte de préservation ou de nouveau baking et un contrôle visuel ; le rapport ne prouve pas l'apparence d'un autre asset artisanal.

## 4. Composer un essai Blender-vers-Godot délimité

Choisissez un détail et un usage cible dans l'observatoire avant de générer de nombreux assets. Sauvegardez le `.glb` d'entrée et un manifeste comprenant SHA source, ID d'objets et de détails, dimensions prévues, arguments de nettoyage, nombre de triangles, rapport UV/matériaux, empreinte de sortie et tâche de visualisation attendue. Produisez référence et candidat depuis cette même entrée. Un premier candidat ne change que `--min-part` ; un autre pourra varier la décimation à premier réglage fixe. Ne changez pas simultanément nettoyage, caméra, lumière et mise à l'échelle pour attribuer ensuite l'amélioration perçue à la modélisation artisanale.

Pour un essai Godot, importez chaque version dans la même scène avec caméra, moteur, viewport, lumières et instantané de données de gouvernance identiques. Consignez erreurs d'import, échelle, images brutes, distribution du temps par image et capacité des réviseurs à identifier détail et sens déclarés sans réponses superposées. Le manifeste et les captures brutes rendent un rejet vérifiable. Les contrôles proposés de zone sûre et de répétabilité de VC-004 sont utiles pour la capture, pas des preuves de lisibilité artisanale. Le chemin de fork DLSS demandé par l'utilisateur exigerait un build pris en charge distinct, un relevé de résolution de rendu et une comparaison performance/qualité ; aucune exécution de ce type n'a eu lieu pour cette leçon.

### Exercice 4 : isoler une variable

Le candidat A utilise `--min-part 0.001`, une cible de 2,000 triangles et la caméra de référence. B utilise `--min-part 0.01`, 1,000 triangles, une nouvelle caméra et un nouvel éclairage. B paraît plus lisible sur une capture. Quelle affirmation est défendable et quelle comparaison devrait suivre ?

> **Réponse :** Vous pouvez seulement rapporter que cette image B combinée paraissait plus lisible avec des réglages modifiés. Vous ne pouvez attribuer le résultat au seuil de faces ou au budget de triangles. Comparez d'abord référence et A avec caméra, lumière et conditions de rendu identiques pour tester la décision sur les petites parties. Changez ensuite une variable supplémentaire à la fois. Préservez captures brutes et résultat d'identification, car un bel ombrage peut masquer un nœud absent.

## 5. Décider si une règle artisanale réutilisable se justifie

Un futur DSL artisanal pourrait décrire `feature`, `meaning`, `source_region`, `preservation_check` et `target_scene` comme déclarations composables. Il ne serait utile que si ces déclarations survivent à l'export/import et réduisent les détails perdus ou le temps de révision par rapport à un simple manifeste avec checklist manuelle. Le script Learn et le plan Godot actuels ne l'implémentent pas. La référence la plus simple est le pipeline GLB existant, un manifeste externe de détails et une révision humaine avant/après.

Déclarez à l'avance un petit benchmark : plusieurs assets versionnés avec des détails connus à conserver et d'autres volontairement supprimables, les mêmes vues et observateurs et un budget borné de triangles/temps par image. Rejetez une condition automatisée de préservation si elle accepte un détail sémantique manquant, bloque la simplification utile plus souvent que la checklist ou exige des annotations impossibles à maintenir. Ne modifiez pas durablement un schéma ou une API publique à partir d'une seule analogie séduisante.

### Exercice 5 : rejeter la mauvaise optimisation

Un candidat respecte le budget de triangles et n'a pas d'erreur d'import, mais trois réviseurs sur quatre ne reconnaissent pas le nœud d'autorité prévu ; la référence obtient quatre bonnes réponses sur quatre. Est-il prêt pour l'observatoire ? Quelles preuves stocker ?

> **Réponse :** Non selon l'objectif déclaré de préservation du sens. Sauvegardez les deux empreintes d'assets, manifestes de nettoyage, rapports, captures brutes de même vue, réponses des réviseurs et résultats de performance. Un nombre de triangles réduit est un gain géométrique réel, mais ne compense pas la perte sémantique observée. Revoyez la géométrie ou texture du nœud et répétez la comparaison contrôlée. Quatre réviseurs constituent un petit essai, pas une estimation pour la population générale.

## Preuves et limites

- La source Learn figée et le rapport d'exemple versionné étayent les opérations et nombres ci-dessus. À [Learn `0eca0022`](https://github.com/spareilleux/learn/blob/0eca002201ba273dfe7348c724bd57ddea9b0568/code/blender/scripts/glb_pipeline.py), le défaut de retour anticipé est toujours présent. Un appel ciblé limité au code source de la fonction proposée `deac6e1` confirme le retour d’une paire ; il n’exécute pas Blender et ne valide pas le pipeline complet. La PR n’est pas considérée comme fusionnée. Aucun processus Blender ou Godot n'a été exécuté pour ce cours ; exemples artisanaux et résultats de réviseurs sont explicitement hypothétiques.
- Le pipeline cible actuellement three.js et joint les maillages ; import Godot, préservation des ID de détails, DSL artisanal et comparaison de fork DLSS sont des travaux ultérieurs proposés.
- Ce brouillon français nécessite encore une révision disciplinaire indépendante, un essai d'apprenant, une révision par une personne maîtrisant le français, la génération/build Learn et une consultation publique anonyme avant publication. La traduction restait à réaliser lors du cycle source anglais antérieur.
