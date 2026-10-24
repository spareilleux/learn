---
module_id: net-006-instance-and-resource-graphs
department: network-science
course: "Graphes d’instances et de ressources"
level: intermediate
prerequisites: [net-002-capability-graphs-and-projections, vc-008-save-and-query-a-weave-scene]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Graphes d’instances et de ressources

> **Brouillon source rédigé par IA.** Les validations par un spécialiste du sujet, des personnes maîtrisant les langues et des apprenants restent à réaliser. La publication du cours en HTML public reste en attente.

Un collègue voit des objets répétés dans le tissage enregistré avec [Godot](https://docs.godotengine.org/en/4.6/classes/class_meshinstance3d.html) et demande : « Quels objets partagent des données, et que toucherait une modification commune ? » Il faut un graphe dont les arêtes représentent les références aux ressources. [NET-002](net-002-capability-graphs-and-projections.md) étudiait des libellés de catalogue ; [VC-008](../../visual-computing/en/vc-008-save-and-query-a-weave-scene.md) testait la persistance d’une scène et les requêtes physiques. Ici, vous choisirez parmi plusieurs graphes du même artefact.

Consultez le [dossier de preuves](../../../../code/streeling/evidence/feedback-projections-2026-10-22/README.md), la [tâche apprenant](../../../../code/streeling/evidence/feedback-projections-2026-10-22/learner-task.md) et l’[extraction du graphe de ressources](../../../../code/streeling/evidence/feedback-projections-2026-10-22/resource-graphs.json). C’est une nouvelle analyse statique des octets conservés, sans nouvelle exécution du moteur. La [scène enregistrée](../../../../code/streeling/evidence/weave-scene-2026-10-22/native-scene.tscn) a pour SHA-256 `7c8003a9e7ea1433cd7e7e18ed83512ca2c436ea0af70bb7415e01e43c3bb4ca`.

## 1. Compter la hiérarchie avant le partage

Pour répondre à « Que contient la racine de cette scène ? », choisissez la hiérarchie : les sommets sont les nœuds de scène et les arêtes orientées vont du parent vers l’enfant. En comptant les types déclarés, elle contient 253 nœuds : 37 nœuds [`Node3D`](https://docs.godotengine.org/en/4.6/classes/class_node3d.html), comprenant la racine et 36 parents de croisements, puis 72 nœuds de chacun des types [`MeshInstance3D`](https://docs.godotengine.org/en/4.6/classes/class_meshinstance3d.html), [`StaticBody3D`](https://docs.godotengine.org/en/4.6/classes/class_staticbody3d.html) et [`CollisionShape3D`](https://docs.godotengine.org/en/4.6/classes/class_collisionshape3d.html). Chaque croisement possède une branche de chaîne et une branche de trame, avec un maillage, un corps et une forme dans chacune.

Le fichier déclare aussi 6 sous-ressources partagées : 2 maillages, 2 formes de collision et 2 matériaux. Une [Resource](https://docs.godotengine.org/en/4.6/classes/class_resource.html) porte des données ; sa déclaration n’ajoute pas un nœud de scène. Additionner déclarations et nœuds mélangerait les rôles des objets. Le [rapport d’exécution antérieur](../../../../code/streeling/evidence/weave-scene-2026-10-22/good-godot-report.json) consigne les nombres d’objets chargés et leur partage ; cette extraction examine la représentation enregistrée.

### Exercice 1 — Distinguer les inventaires

Quelqu’un compte 259 nœuds de scène en ajoutant les ressources. Corrigez ce nombre et expliquez les 37 nœuds `Node3D`.

> **Réponse :** Il y a 253 nœuds de scène et 6 ressources distinctes. Les 37 nœuds `Node3D` comprennent 1 racine et 36 parents de croisements. Les déclarations de ressources n’ajoutent aucun sommet à la hiérarchie.

## 2. Choisir les références comme relation

Pour répondre à « Quels nœuds de scène référencent des données partagées ? », construisez un graphe biparti orienté. À gauche figurent les nœuds de scène ayant une référence `mesh`, `material_override` ou `shape` ; à droite, les objets `SubResource` déclarés. Une référence de propriété fournit une arête orientée, étiquetée par cette propriété. Les propriétés sont des étiquettes d’arêtes, pas des sommets supplémentaires.

Les 72 instances de maillage ont chacune une arête de maillage et une arête de matériau ; les 72 nœuds de forme de collision ont chacun une arête de forme. On obtient donc 144 sommets à gauche, 6 à droite et `72 * 2 + 72 = 216` arêtes. Chaque ressource a un degré entrant de 36. Les 109 autres nœuds de la hiérarchie n’ont aucune de ces références et sont exclus de ce graphe. Cette exclusion ne dit rien de leur importance dans la scène.

Par exemple, `w0-f0/warp` référence `BoxMesh_jk82c` par `mesh`. C’est une relation entre données enregistrées, sans appel de service observé ni collaboration entre auteurs.

### Exercice 2 — Vérifier le décompte biparti

Pourquoi y a-t-il 144 sommets à gauche plutôt que 253 ou 216 ? Donnez le nombre d’arêtes et le degré entrant de chaque ressource.

> **Réponse :** Seules les 72 instances de maillage et les 72 formes de collision participent. Plusieurs propriétés peuvent partir du même sommet. Il y a 216 arêtes, et chacune des 6 ressources a un degré entrant de 36.

## 3. Projeter selon la question posée

Pour répondre à « Quelles instances partagent le même maillage ? », conservez les 72 sommets d’instances de maillage. Reliez 2 sommets distincts par une arête non orientée exactement lorsque leurs propriétés `mesh` désignent le même [`BoxMesh`](https://docs.godotengine.org/en/4.6/classes/class_boxmesh.html) enregistré. Ignorez les matériaux, les formes et les liens hiérarchiques.

La projection possède 2 composantes, chacune étant une clique de 36 sommets : tous les segments de chaîne partagent un maillage, ceux de trame partagent l’autre. Chaque sommet a un degré de 35. Le décompte des paires non ordonnées donne `2 * (36 * 35 / 2) = 1260` arêtes. Ces arêtes résument les références communes ; aucune structure de 1260 arêtes n’a été enregistrée comme hiérarchie de scène. La projection masque aussi la ressource à l’origine de chaque lien : gardez le graphe de références pour le diagnostic.

### Exercice 3 — Compter sans doublons

Calculez le degré, les tailles des composantes et le nombre d’arêtes de la projection des maillages. Pourquoi diviser par 2 ?

> **Réponse :** Degré 35 ; composantes de tailles 36 et 36 ; 1260 arêtes. Dans chaque clique, le décompte des voisins compte chaque paire non orientée deux fois ; la division par 2 corrige ce doublon.

## 4. Encadrer une suppression hypothétique

Supprimez un sommet `BoxMesh` du graphe analytique de références. Ses 36 arêtes incidentes disparaissent ; il reste `216 - 36 = 180` arêtes. Si quelqu’un retirait réellement cette déclaration en conservant les affectations de propriétés de la scène, 36 références de maillage perdraient leur cible. Cette condition précise l’étendue des réparations ; aucune scène n’a été modifiée et aucune défaillance du moteur n’a été observée.

Ces nœuds de maillage référencent aussi des matériaux. Retirer une ressource de maillage ne supprime ni leurs arêtes de matériau ni leur appartenance à la hiérarchie. De même, une coupure de graphe ne prouve pas une erreur de métadonnées : les identifiants de croisement et l’identité des ressources répondent à des questions différentes. Les ObjectID des ressources à l’exécution sont éphémères et ne sont pas les identifiants des croisements sources.

### Exercice 4 — Formuler le résultat borné

Indiquez le nombre d’arêtes restantes et de références touchées après cette suppression hypothétique. Pouvez-vous annoncer un échec de chargement dans Godot ?

> **Réponse :** Il reste 180 arêtes dans le graphe analytique ; 36 références de maillage demanderaient une réparation si la déclaration était réellement supprimée sans les mettre à jour. Aucun échec de chargement n’a été observé : on ne peut donc pas l’annoncer.

## 5. Demander l’expérience manquante

Le partage d’une ressource suggère où une modification pourrait se propager, mais cette extraction ne mesure ni cette propagation ni le coût du rendu. [MeshInstance3D](https://docs.godotengine.org/en/4.6/classes/class_meshinstance3d.html) et [MultiMesh](https://docs.godotengine.org/en/4.6/classes/class_multimesh.html) décrivent des choix de représentation différents. Plusieurs nœuds référençant un même maillage ne suffisent pas à établir l’instanciation par MultiMesh ou le regroupement des appels de dessin. La documentation décrit des capacités ; elle ne mesure pas cette scène.

Pour tester une modification, utilisez une copie de travail, précisez la propriété de ressource à modifier, comparez toutes les instances concernées et conservez les preuves avant/après. Pour tester les performances, fixez la scène, le moteur de rendu, le matériel, la charge et la représentation, puis mesurez plusieurs exécutions comparables. Le [README du laboratoire](../../../../code/streeling/weave-godot/README.md) décrit l’expérience antérieure de persistance, limitée à 36 croisements enregistrés. Aucun de ces graphes n’établit un exporteur général ni la nécessité d’un DSL d’UUID de nœuds.

### Exercice 5 — Choisir les preuves adaptées

Une proposition affirme : « Le partage de ressources a amélioré les performances GPU et une modification du maillage a changé tous les segments de chaîne. » Quelles preuves manquent ?

> **Réponse :** Un benchmark contrôlé avec des mesures de rendu, ainsi qu’une modification de ressource consignée et des comparaisons d’instances. Le graphe statique établit seulement les décomptes de références partagées ; les deux affirmations empiriques restent à vérifier.
