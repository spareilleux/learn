---
module_id: inf-002-optick-compact-vector-information-loss
department: information-theory
course: Perte d’information dans les vecteurs compacts OPTIC-K
level: intermediate
prerequisites: [inf-001-entropy-of-governance]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
research_cycle: information-theory-2026-10-11-002
version: "0.1.0"
---

# Perte d’information dans les vecteurs compacts OPTIC-K

> **Périmètre de la source et du transfert.** Le texte technique ci-dessous provient d’un brouillon archivé. Les mentions historiques d’une absence d’importation ou de compilation dans Learn concernent cette étape antérieure ; ce [dossier de transfert](../../../../code/streeling/evidence/agentic-composition-2026-10-22/README.md) décrit l’importation actuelle et ses vérifications. Les autres expériences indiquées comme non réalisées le restent. Les revues humaines du contenu et de la langue, ainsi que l’essai avec un apprenant, restent à effectuer.

> **Département de théorie de l'information** | Niveau : intermédiaire | Durée estimée : 35 minutes | Statut : brouillon français ; révision du contenu, essai par un apprenant, révision linguistique humaine et révision avant publication en attente

## Objectifs

Après cette leçon, vous saurez :

- Nommer les informations que GA conserve, élimine et normalise lorsqu'il construit un vecteur compact de similarité OPTIC-K.
- Convertir un décalage du schéma brut à 240 positions de GA en un décalage de sa disposition compacte à 124 positions sans confondre les deux systèmes de coordonnées.
- Présenter deux vecteurs bruts différents qui donnent le même vecteur compact et expliquer pourquoi cela prouve l'impossibilité d'une reconstruction unique.
- Vérifier une affirmation de similarité pondérée à l'aide d'une fixture fixe et préciser ce que cette vérification ne dit **pas** de la recherche complète.

## La question du projet

GA stocke des embeddings musicaux pour rechercher des voicings. Son [`EmbeddingSchema.cs` figé](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs) déclare `OPTIC-K-v1.8`, un vecteur brut de dimension 240, les rôles des partitions, leurs poids et l'opération `ExtractCompact`. Un index compact devrait préserver le calcul de similarité dont son lecteur a besoin. Mais que peut déduire un lecteur du vecteur brut d'origine après cette transformation ?

Voici la question réfutable : **si deux vecteurs bruts produisent le même vecteur compact, contiennent-ils nécessairement les mêmes données musicales et d'identité ?** La réponse est non. Nous construirons trois contre-exemples explicites. Cette distinction compte lorsqu'un agent examine un artefact de recherche : une entrée d'index compact apporte une preuve sur une représentation de calcul de score précise ; elle ne copie pas toutes les caractéristiques de départ. Elle évite aussi qu'un ingénieur prenne deux scores compacts égaux pour la preuve qu'une requête de recherche entière, filtres éventuels compris, se comporte de manière identique.

[INF-001](inf-001-entropy-of-governance.md) estimait l'incertitude dans des séquences de tokens de politique. Cette leçon utilise une autre idée de théorie de l'information : une **application plusieurs-vers-un**. Si des entrées distinctes deviennent une même sortie, la sortie ne peut pas déterminer l'entrée de manière unique. Le nombre de dimensions signale une perte possible, mais le contre-exemple en constitue la preuve. Même une représentation comptant autant de positions pourrait perdre de l'information par normalisation.

## 1. Lire le contrat figé, au-delà du seul nombre de positions

Le [registre des partitions](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs#L117-L148) du schéma donne à chaque intervalle brut un début et une fin inclusifs, un rôle et un poids de similarité. Les partitions `Similarity` sont regroupées dans l'ordre du registre. Les partitions `Identity` et `Info` sont absentes du vecteur compact. Le tableau ci-dessous calcule les décalages compacts en additionnant les dimensions conservées ; ces décalages ne sont **pas** des décalages bruts.

| Partition | Positions brutes | Rôle | Poids | Positions compactes |
|---|---:|---|---:|---:|
| IDENTITY | 0–5 | Identity | 0 | omise |
| STRUCTURE | 6–29 | Similarity | 0.45 | 0–23 |
| MORPHOLOGY | 30–53 | Similarity | 0.25 | 24–47 |
| CONTEXT | 54–65 | Similarity | 0.20 | 48–59 |
| SYMBOLIC | 66–77 | Similarity | 0.10 | 60–71 |
| EXTENSIONS | 78–95 | Info | 0 | omise |
| SPECTRAL | 96–108 | Info | 0 | omise |
| MODAL | 109–148 | Similarity | 0.10 | 72–111 |
| HIERARCHY | 149–163 | Info | 0 | omise |
| ATONAL_MODAL | 164–227 | Info | 0 | omise |
| ROOT | 228–239 | Similarity | 0.05 | 112–123 |

Les six largeurs conservées totalisent `24 + 24 + 12 + 12 + 40 + 12 = 124`. Les cinq largeurs omises totalisent `6 + 18 + 13 + 15 + 64 = 116`. Ensemble, elles couvrent les 240 positions brutes. C'est un compte de coordonnées, **pas** un compte de bits ni un taux de compression mesuré : il faudrait préciser la précision numérique, les en-têtes et le format du fichier d'index pour affirmer quoi que ce soit sur le stockage. Le code construit une chaîne de disposition commençant par `optk-v4-pp-r:` et en calcule l'empreinte pour la compatibilité du schéma. Un lecteur devrait établir cette version et cette disposition avant d'interpréter les octets de l'index ; l'exercice ci-dessous n'ouvre aucun index de production.

### Exercice pratique 1 : compter chaque position

Avec des bornes inclusives, combien de coordonnées MODAL apporte-t-elle ? Combien de coordonnées brutes sont absentes du vecteur compact ? L'affirmation « 116 bits perdus » est-elle justifiée ?

> **Réponse :** MODAL apporte `148 - 109 + 1 = 40` coordonnées. Les largeurs conservées totalisent 124 ; `240 - 124 = 116` coordonnées brutes sont donc omises. « 116 bits perdus » n'est pas justifié, car chaque coordonnée est une valeur numérique, pas un bit, et la normalisation perd aussi de l'information à l'intérieur des partitions conservées.

### Exercice pratique 2 : changer de système de coordonnées

Où les positions brutes ROOT 228 et 239 aboutissent-elles dans la disposition compacte ? La position compacte 112 désigne-t-elle la position brute 112 ?

> **Réponse :** ROOT commence après 112 coordonnées conservées ; la position brute 228 devient donc la position compacte 112, et la position brute 239 devient la position compacte 123. La position compacte 112 est la première coordonnée ROOT, tandis que la position brute 112 se trouve dans MODAL. Une étiquette doit préciser son système de coordonnées.

## 2. Ce que la transformation conserve

[`ExtractCompact`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs#L235-L266) lit chaque partition de similarité séparément. Pour une tranche de partition non nulle, elle divise chaque valeur par la norme euclidienne de cette tranche et la multiplie par la racine carrée du poids de la partition. Elle ajoute ensuite la tranche ainsi pondérée au vecteur compact. Une tranche nulle apporte des zéros. En notation mathématique, pour une partition de similarité `p` de tranche brute `x_p` et de poids `w_p`, la tranche compacte non nulle est :

```text
c_p(x) = sqrt(w_p) * x_p / ||x_p||_2
```

Le résultat conserve la **direction** de chaque tranche de similarité non nulle et son poids attribué. Il élimine l'amplitude positive d'origine de la tranche. Une multiplication positive d'une tranche donne la même tranche compacte, à condition que celle-ci reste non nulle. La transformation élimine aussi les valeurs des rôles non sélectionnés par `SimilarityPartitions`. Aucun de ces deux types de perte ne peut être inversé à partir des seules coordonnées compactes.

Le [calculateur de score pondéré](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs#L269-L302) additionne `w_p * cosine(a_p, b_p)` sur les partitions de similarité. Pour des vecteurs de longueur complète et des tranches non nulles, le produit scalaire des deux vecteurs compacts égale cette somme pondérée à la précision des poids stockés près. Le [test de contrat du schéma figé](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Tests/Common/GA.Business.ML.Tests/SchemaLayoutContractTests.cs#L31-L50) vérifie cette relation à `1e-6` près pour des entrées déterministes non nulles. Le test fournit une preuve dans les sources du contrat visé ; cette leçon ne prétend pas avoir relancé les tests C#.

C'est une **représentation qui préserve le score pour la fonction de similarité définie**, pas une archive générale de l'embedding brut. « Préserve la similarité » exige cette précision. Une application peut utiliser IDENTITY pour un filtrage strict, d'autres champs pour l'affichage ou l'analyse, ou un autre parcours de recherche. L'égalité de ces vecteurs compacts ne peut pas établir à elle seule l'égalité des résultats complets de recherche ou du sens musical.

## 3. Une fixture synthétique fixe

Les vecteurs suivants sont des **données construites pour le cours**, pas des embeddings de guitare observés ni des entrées d'index stockées. Les 240 positions sont initialement à zéro. `A` place 1 dans la première position de chaque partition de similarité : les positions brutes `6, 30, 54, 66, 109, 228`. Il place aussi 1 dans la position IDENTITY `0` et la position EXTENSIONS `78`. `B` copie les valeurs de similarité de A, mais déplace le 1 d'IDENTITY de la position brute `0` à `1`, et le 1 d'EXTENSIONS de la position brute `78` à `79`. `C` copie A, sauf que le 1 de ROOT passe de la position brute `228` à `229`. `D` copie A, sauf que la position brute STRUCTURE `6` passe de 1 à 2.

Un calcul Python indépendant a lu les lignes de partitions dans la **révision figée des sources GA** et reproduit la normalisation par partition d'`ExtractCompact` ainsi que le cosinus pondéré pour ces entrées. Il a donné les valeurs suivantes ; ce sont des calculs de fixture, pas une mesure de recherche en production. Les scores sont affichés avec deux décimales, car les poids flottants et les racines carrées peuvent introduire de minuscules écarts d'arrondi.

| Paire | Relation brute | Relation compacte | Score pondéré | Produit scalaire compact |
|---|---|---|---:|---:|
| A/A | identiques | identiques | 1.15 | 1.15 |
| A/B | IDENTITY et EXTENSIONS diffèrent | identiques | 1.15 | 1.15 |
| A/C | les directions one-hot de ROOT diffèrent | différents | 1.10 | 1.10 |
| A/D | l'amplitude de STRUCTURE diffère | identiques | 1.15 | 1.15 |

Chaque vecteur comporte une valeur non nulle dans chaque partition de similarité. Les six contributions d'autocomparaison sont donc `0.45 + 0.25 + 0.20 + 0.10 + 0.10 + 0.05 = 1.15`. Un score supérieur à 1 n'est pas une erreur ici : cette somme pondérée n'est pas une probabilité, et les poids du registre figé totalisent 1.15. Dans A/C, les vecteurs one-hot de ROOT sont orthogonaux ; sa contribution passe donc de 0.05 à zéro tandis que toutes les autres contributions restent fixes.

### Exercice pratique 3 : l'omission crée une véritable collision

Le vecteur compact peut-il distinguer A de B ? Peut-on conclure qu'une requête complète de recherche GA traite A et B de manière identique ?

> **Réponse :** Aucune coordonnée compacte ne peut les distinguer, car leurs six tranches de similarité sont égales ; les deux vecteurs compacts et leurs scores pondérés sont égaux. Leurs vecteurs bruts diffèrent dans IDENTITY et EXTENSIONS, ce qui prouve que la reconstruction du compact vers le brut n'est pas unique. Une requête complète pourrait utiliser IDENTITY comme filtre strict ; l'équivalence de la recherche complète ne s'ensuit donc pas.

### Exercice pratique 4 : perte à l'intérieur d'une partition conservée

Pourquoi D a-t-il le même vecteur compact que A alors que STRUCTURE est conservée ? Le passage de la position brute 6 de 1 à 0 aurait-il la même explication ?

> **Réponse :** La tranche STRUCTURE de A a une norme de 1 ; celle de D, une norme de 2. Diviser chacune par sa propre norme donne la même direction unitaire, puis toutes deux reçoivent la même échelle `sqrt(0.45)`. Passer de 1 à 0 produirait au contraire une tranche STRUCTURE entièrement nulle, que le code laisse à zéro ; ce changement modifierait donc le vecteur compact et son score. La perte d'amplitude positive est la collision démontrée.

### Exercice pratique 5 : formuler une prédiction réfutable

Avant de lire le tableau de la fixture, prédisez `WeightedPartitionCosine(A,C)` et le produit scalaire compact. Donnez une observation concrète qui réfuterait votre prédiction avec l'algorithme figé.

> **Réponse :** Les cinq tranches de similarité inchangées contribuent `0.45 + 0.25 + 0.20 + 0.10 + 0.10 = 1.10` ; les tranches ROOT orthogonales contribuent zéro. Les deux calculs devraient donc donner environ **1.10** et concorder dans la tolérance des nombres flottants. Un score A/C calculé proche de 1.15, avec les positions non nulles et les poids figés indiqués, réfuterait soit la construction de la fixture, soit le comportement de score annoncé, et exigerait d'examiner les sources et le calcul.

## 4. Limites et prochaine vérification

La fixture prouve une propriété limitée de l'application pour une révision figée des sources. Elle ne teste ni la sérialisation de l'index, ni le rejet d'une empreinte de schéma, ni de véritables voicings de guitare encodés, ni la construction des requêtes, ni les filtres, ni les égalités de classement, ni le déploiement actuel. Ceux-ci exigent leurs propres artefacts et tests. Les sources figées indiquent que STRUCTURE dans son ensemble **n'est pas invariante par transposition**, car elle contient un chroma de classes de hauteur ; cette leçon n'utilise pas ses exemples d'égalité compacte pour affirmer le contraire. ROOT joue ici le rôle d'une partition de similarité à 12 positions de faible poids, et ne prouve pas qu'un musicien préférera un résultat particulier.

Pour enquêter sur un véritable index, consignez le commit GA, l'empreinte de schéma dans l'en-tête de l'index, les systèmes de coordonnées brutes et compactes, les filtres éventuels et les artefacts exacts de la requête et des candidats. Comparez ensuite le score et le produit scalaire compact sur ce cas fixe. S'ils divergent au-delà de la tolérance du contrat, l'action utile est un rapport d'écart reproductible, pas une interprétation du score comme qualité musicale. Dans le cycle anglais d'origine, la leçon restait un brouillon en attendant la révision du contenu, un essai d'apprenant, la localisation et la révision avant publication. Ce brouillon français attend encore la révision du contenu, un essai d'apprenant, une révision linguistique humaine et la révision avant publication.

## Sources figées

- [GA `EmbeddingSchema.cs` au commit `dc2e74cbd992a298f67efb928b5b3754615e1924`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs) : version et registre, disposition compacte, extraction et calculateur de score pondéré.
- [GA `SchemaLayoutContractTests.cs` au même commit](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Tests/Common/GA.Business.ML.Tests/SchemaLayoutContractTests.cs) : relation visée entre produit scalaire compact et score pondéré, somme des poids de vecteurs identiques et protection du décalage ROOT.
