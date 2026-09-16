---
title: "Journal"
description: "Notes d'avancement datées — IX épinglé à 490c395, les données extraites de la CI de ce site, la CI du code du cours, dix-neuf endroits où IX diffère du manuel ou de scikit-learn, ce qui a concordé, la carte d'API générée, et les points à vérifier."
sidebar:
  order: 99
---

## Progression

- [x] IX cloné et épinglé au commit `490c395` ; le code du cours dépend de sept de ses crates
- [x] Données : `builds.csv` et `jobs.csv`, extraits de l'historique CI et de l'historique Git de ce dépôt
- [x] CI : formatage, clippy, tests unitaires et chaque exemple comparé avec `expected/` sur trois OS, plus une vérification croisée avec numpy et scikit-learn sous Linux
- [x] Leçon 1 : données, caractéristiques et évaluation
- [x] Leçon 2 : régression linéaire et descente de gradient
- [x] Leçon 3 : classification
- [x] Leçon 4 : partitionnement
- [x] Leçon 5 : composantes principales
- [x] Leçon 6 : ensembles
- [x] Leçon 7 : réseaux de neurones
- [x] Leçon 8 : optimisation
- [x] Annexe : la carte d'API, générée depuis le commit épinglé
- [ ] Leçons 9 à 21
- [x] Traductions française et espagnole

## 2026-09-14 — IX, épinglé

- IX est cloné à part de ma copie de travail, avec `git clone --filter=blob:none`, et extrait à [`490c39533627d296bf9f8f050e6fafc14d7a20c2`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2), un commit de `main` du 2026-09-14, 21:40 UTC. Le workspace a 83 dossiers sous `crates/` (son README annonce 81 crates) ; le cours lit `ix-math`, `ix-supervised`, `ix-optimize`, `ix-unsupervised`, `ix-voicings`, `ix-io` et `ix-agent`, et dépend des cinq premières.
- `Cargo.toml` nomme chaque crate avec `git` et `rev`, et `Cargo.lock` est commité. Cargo récupère une seule fois tout le dépôt IX pour les cinq crates, y compris son sous-module `governance/demerzel`.
- Le code du cours partage `ndarray` 0.17 avec IX : les matrices passent des versions à la main aux fonctions d'IX sans conversion.
- Les outils MCP d'IX de ma session Claude Code m'ont aidé à trouver les algorithmes ; chaque résultat des leçons vient des exemples compilés, pas des outils.

## 2026-09-14 — Les données

- [`data/extract.py`](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/data/extract.py) lit `code/duckdb/data/runs.json` et `jobs.json`, l'export que le [cours DuckDB](../../duckdb/journal/) a fait le 2026-09-14, et exécute `git ls-tree` à chaque commit construit pour compter ses fichiers `.md` et `.mdx`.
- `builds.csv` : les jobs `build` réussis de *Deploy to GitHub Pages*, 65 lignes, avec les secondes de l'étape dont le nom commence par *Install, build*.
- `jobs.csv` : les jobs terminés en succès ou en échec qui ont à la fois une étape de checkout et son étape post, 186 lignes. L'OS est le label du runner sans `-latest`. `queue_s` est le temps entre la création du job et son démarrage.
- Chaque durée est un nombre entier de secondes (la différence de deux horodatages, tronquée). La leçon 1 montre ce que cela fait à l'inférence de tâche d'IX, la leçon 4 ce que cela fait à un mélange gaussien.
- Aucun jeu de données n'a été téléchargé : les deux fichiers sont dérivés de ce dépôt public.

## 2026-09-14 — La CI

- [`ml-ix-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/ml-ix-examples.yml) exécute [`check.sh`](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/check.sh) sur `ubuntu-latest`, `windows-latest` et `macos-latest` : `cargo fmt --check`, `cargo clippy --release --all-targets -- -D warnings`, `cargo test --release` (tests unitaires et doctests, y compris l'import `compile_fail` de la leçon 4), puis chaque exemple, dont la sortie et le code de sortie sont comparés avec `expected/` par `diff --strip-trailing-cr`. `UPDATE=1` réécrit `expected/`, `CROSSCHECK=1` ajoute la vérification Python en local.
- La vérification croisée ne tourne que sous Linux, avec Python 3.13, numpy 2.4.2 et scikit-learn 1.8.0 : elle recalcule les métriques, la droite de régression, l'arbre de décision, les exactitudes des k plus proches voisins, les silhouettes, DBSCAN et un mélange gaussien, et compare sa sortie avec `expected/crosscheck.txt`. Elle ne peut pas rejouer le générateur de nombres aléatoires d'IX, et ne reproduit donc ni les départs de k-means d'IX ni ses découpages aléatoires.
- Les valeurs à virgule flottante sont affichées avec un nombre fixe de décimales (`fmt_vec` dans [`src/lib.rs`](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/src/lib.rs#L47-L51)), si bien que les sorties sont identiques sur les trois systèmes ; aucune n'a eu besoin d'un fichier par OS.
- Les exécutions [34903197003](https://github.com/spareilleux/learn/actions/runs/34903197003) (les exemples des leçons, commit `d9ef7fb`) et [34903462618](https://github.com/spareilleux/learn/actions/runs/34903462618) (les solutions des exercices, commit `15cde43`) ont réussi sur les quatre jobs dès le premier push.

## 2026-09-14 — Choix faits en écrivant le code

- Le `train_test_split`, le k-means++, le départ du GMM et le `StratifiedKFold` d'IX tirent leurs nombres du `StdRng` de Rust, que Python ne peut pas rejouer. Pour ceux-là, la version à la main part du résultat ajusté d'IX et vérifie qu'un pas de plus ne change rien (k-means, EM), et la vérification croisée compare ce qui ne dépend pas du départ : tailles, meilleures inerties sur n départs, log-vraisemblances.
- La leçon 3 teste sur un job sur cinq, un découpage que les deux langages savent faire.
- La leçon 3 exécute `k = 4` à côté de `k = 5` pour le départage des égalités d'IX : l'égalité que j'avais d'abord vue a disparu quand le jeu de test est devenu un job sur cinq, et `k = 4` standardisé en montre de nouveau une, sur une vraie ligne de test.
- La première comparaison de mélange gaussien ne correspondait pas à scikit-learn. En remontant la piste, je suis tombé sur les variances effondrées de `complete_s`, qui sont devenues une section de la leçon 4 au lieu d'une note de bas de page.

## 2026-09-14 — Là où IX diffère

Neuf endroits où la réponse d'IX, ou sa documentation, diffère du manuel ou de scikit-learn, chacun montré par du code compilé dans le cours sauf mention contraire. Aucun n'a fait l'objet d'une issue IX.

1. **Mise à l'échelle avant le découpage.** Avec `normalize` activé, le pipeline ML ajuste `StandardScaler` (et la PCA) sur toutes les lignes, puis découpe : les lignes de test façonnent la mise à l'échelle ([`ml_pipeline.rs`, lignes 190-203](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-agent/src/ml_pipeline.rs#L190-L203), puis [537-538](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-agent/src/ml_pipeline.rs#L537-L538) et [704-705](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-agent/src/ml_pipeline.rs#L704-L705)). Lu dans le code ; le mécanisme est montré dans la [leçon 1](../01-data-and-evaluation/) (première ligne de test à 1.440 contre 1.042), l'outil lui-même n'a pas été exécuté.
2. **Les cibles entières deviennent des classes.** `infer_task_type` qualifie de classification tout vecteur d'étiquettes entières positives ou nulles ayant au plus 20 valeurs distinctes ([`preprocessing.rs`, lignes 234-254](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-math/src/preprocessing.rs#L234-L254)) : les secondes de build donnent `MulticlassClassification { n_classes: 18 }`, et ajouter 0.5 à une ligne donne `Regression`. Le pipeline l'utilise quand la tâche vaut `auto`.
3. **Égalités des k plus proches voisins.** `KNN::predict` utilise `max_by_key`, qui renvoie le dernier maximum : une égalité va au plus grand indice de classe ([`knn.rs`, ligne 53](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/knn.rs#L53)). Sur les jobs standardisés avec `k = 4`, la ligne de test 27 vote `[2, 0, 2]` : IX dit macOS, la version à la main et scikit-learn Ubuntu, le vrai OS ; exactitude de 0.947 contre 0.974.
4. **Un cluster k-means vide part à l'origine.** La mise à jour des centroïdes part de zéros et saute les clusters sans lignes ([`kmeans.rs`, lignes 137-152](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/kmeans.rs#L137-L152)). `KMeans(3)` sur `[5, 5, 9, 9]` donne les centroïdes `[5.0, 9.0, 0.0]`, et `predict([1.0])` renvoie le cluster vide ; scikit-learn donne `[5.0, 9.0, 9.0]` avec un avertissement.
5. **La silhouette d'un singleton vaut 1.** `silhouette_score_exact` dans `ix-voicings` fixe `a = 0` pour une ligne seule dans son cluster, donc `s = 1`, là où Rousseeuw et scikit-learn utilisent 0 ([`lib.rs`, lignes 664-678](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-voicings/src/lib.rs#L664-L678)) : 0.9296 contre 0.5963 sur `[0, 1 | 10]`.
6. **Les imports des tutoriels ne compilent pas.** `use ix_unsupervised::{KMeans, Clusterer};` échoue avec `E0432`, parce que la crate n'exporte que des modules ([`lib.rs`, lignes 5-14](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/lib.rs#L5-L14)). La même forme se trouve dans `docs/unsupervised-learning/kmeans.md` (lignes 60 et 91), `dbscan.md` (ligne 50), `pca.md` (lignes 63 et 101), `docs/use-cases/fraud-detection.md` (ligne 43), `gis-spatial-analysis.md` (lignes 79, 375, 427), `docs/foundations/rust-for-ml.md` (ligne 141), et dans leurs versions françaises. Le doctest du cours vérifie la première.
7. **Un seul départ pour k-means.** `KMeans::fit` lance un seul départ k-means++, et l'outil MCP `ix_kmeans` fixe la graine à 42 ([`handlers.rs`, ligne 322](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-agent/src/handlers.rs#L322)). Sur les jobs, les graines 0 à 9 donnent des inerties de 411.23 à 618.02 ; pour `k = 6`, la graine 42 donne 223.366 là où le meilleur de 50 départs de scikit-learn donne 214.040, avec une silhouette de 0.3646 contre 0.4400.
8. **La règle des voicings ne compare pas.** `ix_voicings::cluster` garde `k = 5` dès que sa silhouette atteint 0.15, et n'essaie `k = 3` qu'en dessous ([`lib.rs`, lignes 770-776](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-voicings/src/lib.rs#L770-L776)). Sur les jobs, elle garde `k = 5` (0.4350) plutôt que `k = 3` (0.4997). Un choix de conception plutôt qu'une erreur, mais le commentaire de documentation présente le seuil comme celui d'« acceptation du partitionnement » (*accepting the clustering*), pas comme celui du choix de `k`.
9. **Effondrement du mélange gaussien.** `GMM` impose à chaque variance un plancher de `1e-6` ([`gmm.rs`, lignes 170-171](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/gmm.rs#L170-L171)) et lance un seul départ aléatoire. Sur les durées en secondes entières, des composantes s'effondrent sur `complete_s`, et la log-vraisemblance dépend de la graine, de −102.666 à 552.879 ; le meilleur de 10 départs de scikit-learn est −102.667. Comparer les log-vraisemblances d'IX choisit le modèle le plus effondré.

Des différences bonnes à connaître, que je ne compte pas comme des erreurs :

- `LogisticRegression` n'a ni régularisation ni test d'arrêt : sur des données séparables, ses poids grandissent avec le nombre d'itérations (leçon 3).
- `ix_optimize::gradient::SGD` est une descente de gradient sur le lot complet : `minimize` lui passe le gradient sur toutes les lignes.
- `DBSCAN` étiquette le bruit `0` et les clusters à partir de `1`, comme le dit sa documentation ; un code écrit pour le `-1` de scikit-learn fond le bruit dans un cluster.
- `ix_io::csv_io::read_csv` transforme les champs texte en `NaN` sans erreur.
- `train_test_split` mélange toujours, et prend les étiquettes de classification en `f64` ; il n'y a pas d'option stratifiée ni chronologique.

## 2026-09-15 — Leçons 5 à 8

- Quatre leçons d'un coup : composantes principales, ensembles, réseaux de neurones, optimisation. Le cours dépend désormais de sept crates IX, `ix-ensemble` et `ix-nn` ayant été ajoutées au même commit épinglé, et exécute seize exemples en CI.
- La vérification croisée a grandi avec elles. La leçon 5 est la première où scikit-learn peut vérifier IX directement et complètement — `PCA` est déterministe, ne prend pas de graine, et a une convention de signe documentée — si bien que chaque nombre de cette leçon a trois sources indépendantes.
- La leçon 6 a introduit un générateur xorshift 64 bits dans le code du cours. IX tire de `StdRng`, que Python ne peut pas rejouer ; trois décalages et trois XOR se rejouent exactement, et la vérification numpy retombe sur les mêmes 48 lignes laissées de côté par le même bootstrap. Cela comble le manque dont se plaignait la note du 2026-09-14, pour les algorithmes que le cours écrit lui-même.
- La leçon 7 est la première à utiliser les différences finies comme oracle plutôt que scikit-learn. Chaque affirmation sur ce que calcule `ix_nn` a été mesurée en bougeant un poids et en regardant la perte, pas déduite d'une lecture — ce qui s'est avéré compter, puisque deux des trois constats se trompent d'un facteur que personne ne devinerait à la lecture du code.
- La leçon 8 n'a rien trouvé à redire aux règles de mise à jour d'`ix_optimize` : SGD, Momentum et Adam suivent les versions à la main pas à pas et atterrissent sur les mêmes points. Le constat, là, porte sur le type de résultat de `minimize`, pas sur son arithmétique.

## 2026-09-15 — Là où IX diffère, suite

Dix autres endroits où la réponse d'IX, ou sa documentation, diffère du manuel ou de scikit-learn, chacun montré par du code compilé dans le cours. Avec les neuf du 2026-09-14, cela fait dix-neuf. Aucun n'a fait l'objet d'une issue IX.

10. **Le ratio de variance expliquée est normalisé sur les composantes retenues.** `explained_variance_ratio` divise chaque valeur propre par la somme des valeurs propres *retenues* ([`pca.rs`, lignes 46-57](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/pca.rs#L46-L57)), si bien que les ratios somment à 1 pour tout `n_components` et que le « proportion of total variance » du commentaire de documentation n'est vrai que si toutes les composantes sont gardées. Sur les jobs standardisés, `PCA::new(2)` rapporte `[0.5635, 0.4365]` là où la vérité, et scikit-learn, disent `[0.3867, 0.2996]`, de somme 0.6863. La question habituelle « combien de composantes pour 90 % ? » ne peut pas lui être posée.
11. **L'itération de puissance part d'un vecteur fixe et peut renvoyer l'axe mineur.** Le départ est `(1, …, 1)/√n` ([`pca.rs`, ligne 107](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/pca.rs#L107)). Sur un nuage de six points étiré le long de `(1, -1)`, de covariance `[[2.4, -1.6], [-1.6, 2.4]]`, ce départ *est* le vecteur propre mineur, donc `PCA::new(1)` renvoie une variance de 0.8 le long de `(1, 1)` au lieu de 4.0 le long de `(1, -1)`. `PCA::new(2)` fait pire : la déflation laisse une matrice qui envoie le départ sur zéro, le garde-fou `norm < 1e-15` se déclenche, et le modèle finit avec deux fois la même composante et une variance de 0. La SVD de scikit-learn renvoie 4.0 et `(0.7071, -0.7071)`. Un cas sur le fil du rasoir — il faut des variances exactement égales — mais rien dans la sortie ne dit dans quel cas on est.
12. **Les variances sont inaccessibles.** `PCA::explained_variance` est un champ privé, et `explained_variance_ratio()` est normalisé comme au constat 10, si bien que `save_state()` est le seul moyen de sortir les valeurs propres d'un modèle ajusté.
13. **Une forêt aléatoire tire ses variables une fois par arbre, pas une fois par division.** Le commentaire de documentation promet « random feature subsets (sqrt(n_features) features per split) » ; le code les tire avant la croissance de l'arbre et construit tout l'arbre à partir de ces colonnes ([`random_forest.rs`, lignes 68-84](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-ensemble/src/random_forest.rs#L68-L84)). Au défaut de trois variables sur cinq, les deux s'accordent, atteignant toutes deux 0.9211 sur les jobs de test ; à `max_features = 1`, la version à la main, qui tire à chaque division, atteint 0.9474 et IX 0.7632, parce que cinquante arbres unidimensionnels ne peuvent pas combiner de variables.
14. **Une égalité dans le vote de la forêt revient au plus grand indice de classe.** `predict` utilise `max_by`, qui garde le dernier maximum ([`random_forest.rs`, ligne 97](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-ensemble/src/random_forest.rs#L97)). Deux souches avec la graine 6 donnent des probabilités `[0.500, 0.500]`, et IX répond la classe 1 là où scikit-learn et `np.argmax` répondent 0. Même forme que le constat 3 sur `KNN::predict`.
15. **`Dense::backward` divise deux fois par la taille du lot.** `grad_output` porte déjà le `1/n` que `mse_gradient` y a mis, et `backward` divise encore par `n` ([`layer.rs`, lignes 40-52](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/layer.rs#L40-L52)). Mesuré contre le gradient par différences centrées de `mse_loss` sur les 65 builds, le rapport vaut exactement 65.0000. L'entraînement converge quand même, puisque chaque couche divise par le même `n`, mais le taux d'apprentissage que vous passez est le taux d'apprentissage divisé par la taille du lot.
16. **`mse_gradient` n'est pas le gradient de `mse_loss` au-delà d'une colonne de sortie.** `mse_loss` moyenne sur les lignes et les colonnes, `mse_gradient` ne divise que par les lignes ([`loss.rs`, lignes 6-16](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/loss.rs#L6-L16)). Mesuré de une à quatre colonnes, le rapport vaut 1, 2, 3, 4. Combiné au constat 15, une couche à deux sorties sur 65 lignes bouge du vrai gradient divisé par 32.5.
17. **`Dense::new` ne prend pas de graine.** Il tire du générateur du fil d'exécution ([`layer.rs`, ligne 27](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/layer.rs#L27)), si bien que deux couches construites dans la même exécution diffèrent déjà et qu'aucun résultat de `Sequential` ne peut être reproduit ni testé contre les régressions. Tous les autres algorithmes aléatoires d'IX en prennent une — `KMeans`, `RandomForest`, `Dropout`, `transformer::FeedForward`. Les champs `weights` et `bias` sont publics, c'est la sortie de secours et c'est ce que fait le cours.
18. **Un `Sequential` de couches `Dense` est une seule application affine.** `Dense` est le seul type qui implémente le trait `Layer` : `ix-nn` n'a aucune couche d'activation que `Sequential::push` pourrait accepter entre deux applications affines. Sur le ou exclusif, deux couches `Dense` convergent vers une perte de 0.25 — la variance des cibles, le mieux qu'une constante puisse faire — et prédisent 0.5 aux quatre coins, tandis que le réseau à la main de même taille, avec une sigmoïde entre ses couches, atteint 0. Après 50 000 époques, la pile satisfait encore `f(0,0) + f(1,1) - f(0,1) - f(1,0) = 0` au dernier bit : elle n'est pas sous-entraînée, elle ne peut pas représenter la fonction. Les vraies non-linéarités du crate vivent dans `transformer::gelu`, à l'intérieur de `FeedForward`, qui travaille sur `Array3` et n'est pas un `Layer`.
19. **`minimize` renvoie le point de départ pour une exécution qui a divergé.** Elle retient le meilleur point traversé et renvoie celui-là ([`gradient.rs`, lignes 124-165](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-optimize/src/gradient.rs#L124-L165)). La descente simple au taux 0.01 sur Rosenbrock part en NaN dès ses premiers pas ; le résultat annonce `best f 24.200000`, qui est `f` au point fourni par l'appelant, avec `converged: false` — le même drapeau qu'obtient une exécution parfaitement bonne qui a simplement épuisé ses itérations. Ni `best_value` ni `converged` ne sépare les deux.

Des différences bonnes à connaître, que je ne compte pas comme des erreurs :

- `RegressionStump` met la moyenne des résidus dans chaque feuille, là où la recette de Friedman et scikit-learn emploient un pas de Newton. C'est une simplification défendable, et la version à la main la copie pour que les deux soient comparables ; avec elle, IX et la version à la main s'accordent sur chacune des 38 lignes de test à 1, 5, 10, 25 et 50 tours.
- `GradientBoostedClassifier` n'a ni arrêt anticipé ni score sur un jeu réservé. Sur les jobs il culmine à 0.9474 après cinq tours et se stabilise à 0.9211 dès vingt-cinq, et rien dans l'API ne le mesure.
- `ix-ensemble` n'a pas de score out-of-bag, que le bagging offre gratuitement et que scikit-learn expose par `oob_score=True`.
- `ClosureObjective` ne redéfinit jamais `ObjectiveFunction::gradient`, si bien qu'envelopper une closure achète silencieusement un gradient mesuré au prix de deux évaluations supplémentaires par coordonnée et par pas — 1001 évaluations contre 201 pour 200 pas d'Adam en deux dimensions. Sur un objectif lisse, cela ne coûte rien en précision : les deux exécutions ont fini à `1.061e-16`.

## 2026-09-15 — Ce qui a concordé

Cela mérite d'être consigné à côté des constats, car les leçons ont surtout trouvé l'inverse jusqu'ici :

- Les SGD, Momentum et Adam d'`ix_optimize` suivent exactement les versions à la main — mêmes nombres de pas (5000, 4129, 2822), mêmes points finaux, même premier pas depuis le même gradient.
- `GradientBoostedClassifier` suit la version à la main sur chaque ligne de test à chaque nombre de tours, et numpy reproduit les mêmes exactitudes, les mêmes log-priors lissés et les mêmes souches du premier tour.
- Les cinq variances de `PCA` correspondent à celles de Jacobi à `1.28e-10` près et à celles de scikit-learn aux chiffres affichés ; seuls le ratio et le vecteur de départ fixe sont en cause.

## 2026-09-15 — La carte d'API

- Le plan promet une leçon par famille d'algorithmes, ce qui laissera encore l'essentiel du workspace intouché. [`scripts/sync-ix-api-map.mjs`](https://github.com/spareilleux/learn/blob/main/scripts/sync-ix-api-map.mjs) comble le manque par l'autre bout : un seul `git grep` sur le commit épinglé, et une page générée par locale listant chaque déclaration `pub` sous `crates/*/src/`, crate par crate et module par module. 80 crates, 3398 déclarations, dont 2307 fonctions.
- Elle est générée, jamais écrite à la main, et `npm run sync:ix-api-map` la reconstruit — elle ne peut donc pas s'écarter du pin, ce qui est d'ordinaire ce qui pourrit une page de ce genre. La révision est lue dans le `Cargo.toml` du cours plutôt qu'écrite deux fois.
- Elle compte ce que dit la source, pas ce qu'un appelant peut atteindre : un `pub` dans un module privé est listé et reste invisible depuis l'extérieur du crate. Le constat 12 — un champ privé qui rend le ratio inutilisable — est exactement le genre de chose que la page ne peut pas dire, et que les leçons peuvent.

## À vérifier

- L'outil `ix_ml_pipeline` de bout en bout : l'ordre de mise à l'échelle du constat 1, l'inférence de tâche du constat 2 sur un fichier CSV, et l'erreur `All rows contain NaN values` pour un fichier avec une colonne texte. Les trois sont lus dans le code, pas exécutés.
- `LinearRegression::fit` sur deux caractéristiques identiques : si `ix_math::linalg::inverse` renvoie une erreur et que `fit` panique, ou s'il renvoie une mauvaise réponse.
- Un cluster k-means qui se vide au milieu d'une exécution réelle, plutôt qu'au départ comme dans le constat 4.
- `ix_voicings::cluster` sur les voicings de GA : l'export demande le `FretboardVoicingsCLI` de GA, que le cours ne construit pas.
- La cause du build de 48 secondes de `95a3830`.
- Si les constats 1 à 9 sont déjà connus en amont : je n'ai pas cherché dans les issues d'IX.
- Les exemples sur les runners Linux ARM : la CI couvre seulement `ubuntu-latest` (x64), `windows-latest` et `macos-latest` (ARM).
- Si `PCA` renvoie parfois des variances non triées sur de vraies données, plutôt que sur le nuage construit du constat 11.
- Si un `Sequential` plus profond que deux couches `Dense` est utilisé quelque part dans IX, où le constat 18 mordrait.
- `ix-autograd` : son ruban est le crate qui devrait rendre le constat 15 inutile, et la leçon 12 le mesurera.
- Si les constats 10 à 19 sont déjà connus en amont : je n'ai toujours pas cherché dans les issues d'IX.
- La carte d'API compte les déclarations `pub`, pas celles qui sont atteignables ; l'écart entre les deux nombres n'est pas mesuré.
