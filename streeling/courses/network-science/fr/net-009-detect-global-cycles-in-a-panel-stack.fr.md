---
module_id: net-009-detect-global-cycles-in-a-panel-stack
department: network-science
course: "Détecter les cycles globaux dans un empilement de panneaux"
level: intermediate
prerequisites: ["net-006-instance-and-resource-graphs", "sem-008-interpret-layer-order-relative-to-the-reference-normal"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Détecter les cycles globaux dans un empilement de panneaux

> **Portée du brouillon.** Graphes abstraits pédagogiques et lecture du code et des tests à une révision précise. Aucune nouvelle géométrie FOLD, exécution native d'IX, mise à l'épreuve de panneaux physiques ou essai de fabrication n'ont été produits. Les revues humaines technique, artisanale, linguistique et pédagogique restent à effectuer ; le HTML du cours déployé fait l'objet d'une vérification distincte.

## La question du projet

L'observatoire peut-il accepter chaque croisement individuel d'un tissage et néanmoins échouer à placer les panneaux rigides à des hauteurs globalement cohérentes ? L'[ADR d'IX sur les panneaux parallèles à la révision fixée](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/docs/adr/0007-origami-thickness-as-parallel-rigid-panels.md) distingue une lecture locale des couches d'une hauteur unique par panneau rigide parallèle. Son épaisseur est l'épaisseur totale dans les unités du motif de plis, et non automatiquement en millimètres. [SEM-008](../../semiotics/en/sem-008-interpret-layer-order-relative-to-the-reference-normal.md) explique comment une relation de couches fournie devient un énoncé interprété de position au-dessus ou au-dessous.

Ici, une arête orientée va du panneau inférieur au panneau supérieur. Le [code d'épaisseur](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/thickness.rs#L142-L204) utilise cette convention après fusion des faces reliées par des joints plats. Son arête unitaire de graphe n'est ni une force physique ni une hauteur mesurée.

## 1. Sommer les contraintes globales

Utilisez quatre panneaux pédagogiques et les arêtes `A->B`, `B->C`, `C->D`, `D->A`. Pour une épaisseur totale positive `t`, exigez `z_upper>=z_lower+t` pour chaque arête. La somme annule les quatre variables de hauteur et donne `0>=4*t`. Une épaisseur positive rend cela impossible dans ce modèle de panneaux parallèles.

Chaque croisement peut malgré tout avoir une paire inférieure/supérieure localement cohérente. La contradiction apparaît lorsque ces relations doivent partager la même hauteur de panneau entre différents croisements. Ces étiquettes pédagogiques ne sont pas les identifiants de faces d'un nouveau jeu d'essai IX exécuté.

### Exercice 1 : exhiber la contradiction globale

Écrivez les quatre inégalités de séparation et leur somme pour `t=0.5` unité du motif de plis. L'échec de ce modèle global signifie-t-il que chaque croisement individuel était localement contradictoire ?

> **Réponse:** Les inégalités sont `z_B>=z_A+t`, `z_C>=z_B+t`, `z_D>=z_C+t` et `z_A>=z_D+t`. Leur somme donne `0>=4*t`, donc `0>=2`, ce qui est faux. Le cycle couple différents croisements par une hauteur unique par panneau ; un seul croisement local ne contient pas nécessairement de contradiction.

## 2. Préserver le cas limite d'épaisseur nulle

À `t=0`, les mêmes inégalités permettent à toutes les hauteurs de coïncider. Le graphe orienté possède toujours un cycle. Le [test de tissage à la révision fixée](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/tests/thickness.rs#L281-L305) attend une analyse de couches réussie alors que la lecture rigide signale un cycle. Le refus est conditionné par une épaisseur positive.

Pour ce cas cyclique du code, `rigid.levels` et `rigid.height` restent null même à épaisseur nulle ; la hauteur locale distincte des couches est nulle. Ne remplacez pas un témoin rigide absent par un témoin numérique inventé. Ce sont des assertions lues dans le code des tests, et non de nouveaux résultats de tests.

### Exercice 2 : distinguer l'état du graphe du refus

À épaisseur nulle, un adaptateur peut-il reformuler « non refusé » en « acyclique » ? Que change une épaisseur positive, et l'un de ces résultats certifie-t-il la fabrication ?

> **Réponse:** Non. Le graphe reste cyclique ; l'épaisseur nulle désactive seulement ce refus d'empilement rigide à épaisseur positive. À épaisseur positive, le même cycle refuse ce modèle, sans témoin de niveaux ou de hauteur rigides. Ni une acceptation ni un refus ne certifient la possibilité de fabriquer un véritable objet tissé, incliné ou déformable.

## 3. Supprimer une arête et calculer les niveaux

Supprimez `D->A`. La chaîne restante possède les niveaux `A=0`, `B=1`, `C=2`, `D=3`. Le plus long chemin orienté comporte trois arêtes et quatre niveaux de panneaux. Avec `t=0.5`, les décalages de niveaux sont `[0,0.5,1,1.5]` dans les unités du motif de plis.

Selon une convention pédagogique d'enveloppe de couche complète, chaque panneau occupe l'espace depuis son décalage jusqu'à une épaisseur totale au-dessus. L'étendue totale est donc de 2 unités, tandis que le plus haut décalage vaut 1.5. Cela illustre le nombre de niveaux multiplié par l'épaisseur totale du rapport du code ; cela ne place pas de panneaux physiques dans une scène native.

### Exercice 3 : distinguer décalages et étendue

Calculez le nombre de niveaux, le plus haut décalage et l'étendue complète de l'enveloppe. Cette affectation de niveaux est-elle un placement canonique unique de l'objet ?

> **Réponse:** Il y a quatre niveaux, un décalage maximal de 1.5 unité et une étendue totale de 2 unités. Un témoin valide de niveaux n'est pas un placement canonique unique : la translation et d'autres dispositions admissibles peuvent différer. Le graphe abstrait fixé et la convention d'enveloppe n'établissent ni la géométrie exacte d'un pli épais ni les dégagements du mouvement.

## 4. Fusionner les identités et conserver les relations inconnues

Avant fusion, les arêtes de faces `1->2` et `2->0` forment un graphe acyclique. Si les faces 0 et 1 sont reliées à plat et doivent partager un panneau rigide, la correspondance de panneaux est `[0,0,2]`. Les arêtes de panneaux obtenues sont `0->2` et `2->0` : un cycle. [NET-006](net-006-instance-and-resource-graphs.md) demande de même quelles entités représente un graphe ; un graphe de faces et un graphe de panneaux n'ont pas nécessairement les mêmes contraintes.

Considérez séparément les arêtes connues `A->B` et `C->D`, avec la paire superposée B/C indéterminée. Le graphe connu possède deux niveaux. Le compléter avec `B->C` en exige quatre, tandis que `C->B` en permet deux. Avec deux couches locales posées, la lecture à deux niveaux inspirée du code n'est qu'une borne inférieure tant que cette paire reste inconnue ; les niveaux exacts des faces ne sont pas émis.

### Exercice 4 : effectuer les deux opérations sur les graphes

Expliquez le cycle créé par la fusion au joint plat. Pour le graphe distinct à paire inconnue à `t=0.5`, calculez les deux étendues possibles après complétion et expliquez pourquoi la lecture partielle ne peut pas être qualifiée d'exacte.

> **Réponse:** La fusion identifie les faces 0 et 1, transformant le chemin de faces en cycle de panneaux `0->2->0`. Pour l'exemple de paire inconnue, les deux complétions exigent quatre et deux niveaux, donnant des étendues de 2 et 1 unités. La valeur partielle de deux niveaux est une borne inférieure, et non une décision sur la relation manquante. Aucune nouvelle géométrie ou vérification native n'a produit ces exemples abstraits.

## 5. Garder le témoin du graphe avec son affirmation

Le [module de couches](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/layers.rs#L92-L118) interprète les relations fournies à l'aide de l'orientation des faces. Le module d'épaisseur fusionne ensuite les panneaux, déduplique les arêtes de panneaux et conserve un témoin de paire de faces pour un cycle. Les relations inconnues entre faces superposées restent un décompte distinct ; un graphe connu acyclique ne les rend pas connues.

### Exercice 5 : préparer un refus avec accès aux sources

Lisez l'ADR, le code et le test. Remplacez « le tissage est impossible » par un rapport délimité et précisez ce qu'un futur adaptateur d'observatoire devrait préserver avant de proposer un autre DSL de création.

> **Réponse:** Rapportez que les relations déclarées n'admettent aucun empilement d'épaisseur positive avec une hauteur fixe par panneau rigide parallèle, et conservez les témoins de faces inférieures et supérieures du cycle, la correspondance de panneaux, l'interprétation de l'orientation et des signes, les unités d'épaisseur, le nombre de paires inconnues et la révision du code. Cela n'affirme rien d'universel sur les panneaux inclinés, les fils souples, le mouvement de pliage ou la fabrication. Comparez un relevé typé de graphe et le vérificateur existant avant d'ajouter un DSL. Aucun adaptateur ni essai physique n'a été livré ici.

Le [relevé de graphes fixé](../../../../code/streeling/evidence/constraint-feedback-2026-10-22/panel-graphs.json) conserve tous les cas pédagogiques indépendamment des identifiants du jeu d'essai du code.
