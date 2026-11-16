---
module_id: dv-007-optick-partition-small-multiples
department: data-visualization
course: Petits multiples pour les diagnostics des partitions OPTIC-K
level: intermediate
prerequisites: [dv-001-observed-degraded-stale-quality, dv-006-position-length-area-comparisons]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
research_cycle: data-visualization-2026-10-11-007
version: "0.1.0"
---

# Petits multiples pour les diagnostics des partitions OPTIC-K

> **Département de visualisation des données** | Niveau : intermédiaire | Durée estimée : 35 minutes | Statut : brouillon de traduction ; relecture humaine du fond, relecture linguistique par une personne maîtrisant le français, essai par un apprenant et examen avant publication en attente

Données pour les exercices hors ligne : [six instantanés GA figés](../../../../code/streeling/fixtures/data-visualization/historical-ga/README.md). Ces données sont historiques ; le comportement actuel du service n'est pas évalué.

## Objectifs

À la fin de ce cours, vous saurez :

- déterminer quand les petits multiples aident à comparer la **même mesure diagnostique** entre partitions OPTIC-K ;
- garder les échelles, la référence, l'échantillon et le classifieur fixes entre panneaux, tout en indiquant le rôle et la dimension de chaque partition ;
- distinguer les décalages du vecteur compact d'un diagnostic de ceux du vecteur brut du schéma ;
- expliquer pourquoi la prédictibilité de l'instrument ne teste ni l'invariance par transposition ni la qualité de la recherche musicale.

## La question du projet

Un ingénieur GA souhaite examiner l'information sur l'instrument dans l'embedding OPTIC-K. À la révision GA épinglée [`dc2e74c`](https://github.com/GuitarAlchemist/ga/tree/dc2e74cbd992a298f67efb928b5b3754615e1924), le [diagnostic des embeddings du 25 juin 2026](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/embeddings/2026-06-25.json) enregistre l'exactitude d'un classifieur qui prédit l'instrument pour six partitions. Le tableau de bord doit-il afficher un diagramme en barres classé de « qualité des partitions », six petits graphiques ou un score global unique ?

Choisissez **six petits multiples alignés** pour cette comparaison précise : un panneau par partition testée, chacun montrant la même exactitude de classification de l'instrument sur une échelle de 0–100%, avec la **référence du hasard de 33.33% pour trois classes équilibrées** répétée. Ce diagnostic figé a échantillonné 12,000 éléments, 4,000 par instrument, utilisé cinq plis et nommé une forêt aléatoire de 30 arbres d'une profondeur maximale de 10. Ces champs méthodologiques doivent figurer dans la légende commune. Chaque panneau doit indiquer le nom de la partition, sa dimension, son rôle dans le schéma, la moyenne observée et les propres étiquettes d'hypothèse/d'état du diagnostic. Un tableau doit donner les valeurs exactes.

Le [registre canonique `EmbeddingSchema.cs`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs) déclare `Version = OPTIC-K-v1.8` et `TotalDimension = 240`. Ses partitions de similarité comprennent STRUCTURE, MORPHOLOGY, CONTEXT, SYMBOLIC, MODAL et ROOT. C'est pourquoi ces six panneaux forment un ensemble cohérent. Il s'agit d'un diagnostic historique d'un index figé, et non de l'état actuel des embeddings.

### Exercice 1 : choisir l'ensemble de panneaux

Pourquoi six panneaux sont-ils préférables ici à un score unique de « qualité des embeddings » ? Faut-il donner à IDENTITY, SPECTRAL et HIERARCHY des panneaux d'exactitude vides ?

> **Réponse :** Les six partitions de similarité testées ont toutes la même mesure de classification de l'instrument ; des panneaux répétés permettent donc une comparaison à unité identique tout en conservant leurs rôles différents. Un seul score de qualité combinerait des interprétations distinctes. IDENTITY a un rôle de filtre strict, et SPECTRAL et HIERARCHY ont des rôles informatifs dans le registre canonique ; le diagnostic figé ne donne aucune ligne de classifieur pour ces partitions. N'inventez pas de panneaux d'exactitude nulle. Si le schéma complet doit apparaître, listez-les séparément comme « non mesurées dans ce diagnostic ».

## 1. Garder une même échelle et montrer les nombres

Donnez aux six panneaux le même axe horizontal de 0–100%. Placez une ligne de référence au niveau du hasard enregistré, **33.33%**, et un point à chaque moyenne d'exactitude. N'ajustez pas automatiquement un panneau à 30–40% et un autre à 85–95% : une petite différence autour du hasard semblerait alors aussi grande que l'écart entre le hasard et 90%. Utilisez un libellé numérique direct, et non un code de « fuite » porté uniquement par la couleur. Les cinq valeurs des plis enregistrées pourraient apparaître comme de petites marques secondaires, mais ce sont les plis d'une seule exécution, et non cinq déploiements indépendants ni un intervalle de confiance.

[DV-006](dv-006-position-length-area-comparisons.md) présente le choix d'une échelle partagée pour comparer ; les panneaux répétés l'appliquent ici à une mesure diagnostique unique.

| Panneau | Positions brutes dans le schéma | Rôle | Moyenne du diagnostic | Étiquette du diagnostic |
|---|---:|---|---:|---|
| STRUCTURE | 6–29 (24 dimensions) | Similarité | 50.20% | `likely_leak` ; confirmée |
| MORPHOLOGY | 30–53 (24 dimensions) | Similarité | 90.32% | `by_design` ; non confirmée comme fuite |
| CONTEXT | 54–65 (12 dimensions) | Similarité | 33.33% | `possible` ; non confirmée |
| SYMBOLIC | 66–77 (12 dimensions) | Similarité | 53.74% | `likely_leak` ; confirmée |
| MODAL | 109–148 (40 dimensions) | Similarité | 48.70% | `possible` ; confirmée |
| ROOT | 228–239 (12 dimensions) | Similarité | 34.98% | `by_design` ; non confirmée comme fuite |

Les pourcentages ci-dessus sont les valeurs `accuracy_mean` de l'instantané, arrondies à deux décimales. Les notes de l'instantané donnent une exactitude supérieure à **0.40** pour son problème équilibré à trois classes comme critère de « fuite confirmée », mais les étiquettes `by_design` comptent : MORPHOLOGY est physiquement liée à un instrument, donc ses 90.32% ne doivent pas en faire le panneau d'échec le plus rouge. Affichez les champs enregistrés `leak_hypothesis` et `leak_confirmed` comme texte plutôt que de reconstituer une alarme à partir de la seule exactitude.

### Exercice 2 : utiliser la référence partagée

De combien STRUCTURE et CONTEXT dépassent-elles la référence du hasard affichée de 33.33%, en points de pourcentage ? Un axe vertical distinct pour chaque panneau faciliterait-il cette comparaison ?

> **Réponse :** STRUCTURE est à `50.20 - 33.33 = 16.87` points de pourcentage au-dessus de la référence affichée. CONTEXT est à `33.33 - 33.33 = 0.00` point au-dessus, à la précision affichée. Des axes séparés ajustés automatiquement masqueraient l'ordre de grandeur commun ; utilisez la même échelle de 0–100% et indiquez les deux valeurs. Ce calcul décrit le diagnostic figé du classifieur, et non un test de significativité statistique.

## 2. Séparer la mesure de l'interprétation

Chaque panneau indique **avec quelle exactitude ce classifieur précis a prédit l'instrument à partir du vecteur de cette partition**. Il ne dit pas si la partition est « bonne ». Une partition de réalisation physique comme MORPHOLOGY est censée conserver de l'information sur l'instrument. Les valeurs de 50.20% pour STRUCTURE et de 53.74% pour SYMBOLIC sont marquées comme fuites confirmées par le diagnostic enregistré ; ce sont des pistes d'enquête selon son critère. Les six partitions ont aussi des dimensions et des significations différentes ; ce graphique ne permet donc pas d'attribuer les écarts d'exactitude à un mécanisme causal unique. La valeur de 83.11% de `full_classifier_accuracy` est un résultat distinct sur le vecteur complet, et non une septième partition à classer avec ces panneaux.

Annotez les panneaux avec le rôle et l'hypothèse enregistrée, en regroupant éventuellement les interprétations « prévu par conception » et « à examiner » de part et d'autre d'une fine séparation. Gardez l'échelle de position numérique inchangée. La couleur peut renforcer le texte, mais elle ne doit pas être le seul moyen de reconnaître un état diagnostique. Placez la date et la méthode dans une légende commune pour éviter de les répéter au point d'étouffer les données.

### Exercice 3 : rejeter un faux classement

Une personne chargée de la relecture dit : « MORPHOLOGY est la pire partition à 90.32%, tandis que CONTEXT est la meilleure à 33.33%. » Corrigez cette affirmation à l'aide du rôle dans le schéma et des champs du diagnostic.

> **Réponse :** Les moyennes classent la capacité de ce classifieur à déduire l'instrument, et non la qualité des partitions. MORPHOLOGY représente la réalisation physique et porte l'étiquette `by_design` avec `leak_confirmed: false` dans l'artefact figé ; une forte prédictibilité de l'instrument y est attendue. CONTEXT est proche de la référence du hasard enregistrée et porte l'étiquette `possible` avec `leak_confirmed: false`, mais cela seul n'établit ni un encodage utile du contexte ni les performances de recherche.

## 3. Indiquer le système de coordonnées présenté

Le vecteur brut du schéma canonique a **240 dimensions**. Il place STRUCTURE aux positions brutes **6–29** et ROOT aux positions **228–239**. Le diagnostic de juin décrit un index avec `corpus.dims: 124` et indique pour STRUCTURE les coordonnées compactes `start: 0`, `end: 24`, `dims: 24` ; ROOT apparaît à `start: 112`, `end: 124`, `dims: 12`. Ces valeurs de `end` sont exclusives d'après le calcul entre les champs enregistrés `start`, `end` et `dims`. Les partitions de similarité du schéma sont regroupées dans la vue compacte de 124 dimensions, qui omet les partitions d'identité et d'information. Nommez explicitement les coordonnées brutes et compactes. Sinon, le lecteur peut confondre deux systèmes de coordonnées valides avec une dérive du schéma.

Ne placez pas les indices des positions brutes sur l'axe d'exactitude du diagnostic : une position n'est ni un pourcentage ni un score. Si le cours a besoin d'une vue de la disposition, utilisez une bande séparée avec les plages brutes et les rôles ; gardez les six panneaux de pourcentages alignés du diagnostic pour les résultats du classifieur.

### Exercice 4 : faire correspondre les décalages

Le diagnostic indique `STRUCTURE start=0, end=24, dims=24`, tandis que le schéma indique les positions brutes 6–29. Cela prouve-t-il que le diagnostic a utilisé la mauvaise partition ? Quelle serait la plage compacte de ROOT ?

> **Réponse :** Non. Le diagnostic décrit l'index compact de 124 dimensions, dont la plage STRUCTURE est `[0,24)` ; la plage brute de STRUCTURE dans le schéma couvre les positions 6 à 29. La plage de ROOT dans le diagnostic est `[112,124)` pour 12 dimensions, tandis que sa plage brute couvre les positions 228 à 239. Précisez le système de coordonnées et la convention de borne finale près de chaque disposition avant de comparer les décalages.

## 4. Préserver la portée de l'affirmation

Le schéma indique que ROOT a été séparée en v1.8 pour faire concorder STRUCTURE entre les **voicings du même ensemble de classes de hauteurs**, indépendamment de l'octave, du voicing ou de l'instrument. Il avertit aussi que STRUCTURE dans son ensemble contient le chroma des classes de hauteurs et **n'est pas invariante par transposition** ; seules ses sous-dimensions ICV et de cardinalité ont cette propriété. L'exactitude de classification de l'instrument ne teste aucune de ces affirmations d'invariance. Un résultat distinct du diagnostic figé indique une concordance moyenne des ensembles de classes de hauteurs de 100% parmi les dix premiers résultats de 50 requêtes testées, mais cette mesure de recherche porte sur une autre tâche et un autre échantillon. Si elle est montrée, il lui faut son propre panneau ou tableau et son dénominateur, et non un septième point sur l'échelle d'exactitude.

Le [rapport de qualité du 23 juillet](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/docs/quality/README.md) marque ses cinq flux suivis de partitions d'embeddings comme périmés : leur dernière observation réelle date du 25 juin, soit 28 jours avant ce rapport. La valeur distincte de ROOT est datée du 25 juin par l'instantané épinglé du diagnostic, et non par un flux ROOT dans ce rapport. Un graphique de petits multiples peut représenter fidèlement le 25 juin tout en étant impropre à décrire l'état opérationnel actuel. Datez la visualisation selon l'observation source et liez à la fois l'instantané source et la révision du schéma.

[DV-001](dv-001-observed-degraded-stale-quality.md) explique pourquoi une observation historique et un état opérationnel actuel nécessitent des légendes différentes.

### Exercice 5 : rédiger la légende du tableau de bord

Rédigez deux phrases pour le graphique à six panneaux. Incluez la date épinglée, la mesure, la référence et une limite d'interprétation. Corrigez cette affirmation proposée : « La faible fuite de ROOT prouve que STRUCTURE est invariante par transposition et que l'index en service est sain. »

> **Réponse :** « Dans le diagnostic des embeddings GA du 25 juin 2026 à la révision `dc2e74c`, six panneaux alignés montrent l'exactitude moyenne de classification de l'instrument par partition de similarité sur un axe partagé de 0–100%, avec la référence du hasard de 33.33% pour trois classes équilibrées. Les étiquettes de rôle et de fuite du diagnostic nuancent ces pourcentages et il ne teste pas l'invariance par transposition ; le rapport du 23 juillet marque cinq flux suivis de partitions comme périmés, tandis que ROOT est datée par le diagnostic lui-même, de sorte que le graphique ne peut pas établir l'état actuel de l'index. »

## À retenir

- Les petits multiples fonctionnent ici parce que les six panneaux partagent une mesure diagnostique et une échelle.
- Conservez le rôle, les dimensions et l'interprétation enregistrée de chaque partition près de son nombre.
- Les coordonnées brutes du schéma à 240 dimensions et les coordonnées compactes de l'index à 124 dimensions servent des dispositions différentes.
- La prédictibilité de l'instrument, la recherche d'ensembles de classes de hauteurs, l'invariance pour un même ensemble et l'invariance par transposition sont des questions différentes.
- Datez un artefact figé et montrez son caractère périmé avant que les lecteurs n'agissent sur cette base.

## Éléments du projet et limites

- GA : [schéma canonique](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs), [diagnostic des embeddings du 25 juin](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/embeddings/2026-06-25.json) et [rapport de qualité du 23 juillet](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/docs/quality/README.md), tous épinglés. Le registre du schéma et les constantes de version font autorité pour ce cours ; d'anciens commentaires en prose dans ce fichier décrivent encore des dispositions antérieures du schéma.
- La disposition en petits multiples est une proposition pédagogique, et non un tableau de bord GA publié. Le diagnostic est une seule exécution figée avec un classifieur, un échantillon équilibré et un index particuliers ; il n'établit ni le comportement actuel ni les sources causales de l'information sur l'instrument. La relecture humaine du fond, l'essai par un apprenant, la relecture linguistique et la vérification de la version publique Learn restent en attente.

*Recherche : `data-visualization-2026-10-11-007`. Brouillon de traduction uniquement ; relecture et publication en attente.*
