---
title: "3. Clasificación: regresión logística, k vecinos más cercanos, árboles de decisión"
description: Qué sistema operativo ejecutó un job de CI, a partir de los tiempos de sus pasos — regresión logística por descenso de gradiente, k vecinos más cercanos con y sin escalado, un árbol de decisión CART con la impureza de Gini, y validación cruzada estratificada, cada uno escrito a mano y comparado con ix-supervised y scikit-learn, incluido un empate que IX resuelve al revés.
sidebar:
  order: 3
---

La regresión predice un número; la **clasificación** predice una clase. Esta lección predice el sistema operativo de un job de CI, Ubuntu, Windows o macOS, a partir de cinco tiempos en segundos: `queue_s` (la espera de un runner), `setup_s` (el paso *Set up job*), `checkout_s` y `post_checkout_s` (el checkout y su limpieza), y `complete_s` (el paso *Complete job*). La lección 1 dio la línea base: siempre Ubuntu, 65 % de exactitud, F1 macro 0.263.

Tres clasificadores, tres ideas de lo que significa «aprender»: una suma ponderada pasada por una curva, los ejemplos más cercanos, y una lista de preguntas.

| | ML.NET | Tribuo | scikit-learn | IX |
|---|---|---|---|---|
| Regresión logística | [`LbfgsLogisticRegression`](https://learn.microsoft.com/dotnet/api/microsoft.ml.standardtrainerscatalog.lbfgslogisticregression) | [`LogisticRegressionTrainer`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/classification/sgd/linear/LogisticRegressionTrainer.html) | [`LogisticRegression`](https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.LogisticRegression.html) | `ix_supervised::logistic_regression` |
| k vecinos más cercanos | — | [`KNNTrainer`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/common/nearest/KNNTrainer.html) | [`KNeighborsClassifier`](https://scikit-learn.org/stable/modules/generated/sklearn.neighbors.KNeighborsClassifier.html) | `ix_supervised::knn::KNN` |
| Árbol de decisión | árboles potenciados: [`FastTree`](https://learn.microsoft.com/dotnet/api/microsoft.ml.trainers.fasttree.fasttreebinarytrainer) | [`CARTClassificationTrainer`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/classification/dtree/CARTClassificationTrainer.html) | [`DecisionTreeClassifier`](https://scikit-learn.org/stable/modules/tree.html) | `ix_supervised::decision_tree::DecisionTree` |
| Validación cruzada | [`CrossValidate`](https://learn.microsoft.com/dotnet/api/microsoft.ml.multiclassclassificationcatalog.crossvalidate) | [`CrossValidation`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/evaluation/CrossValidation.html) | [`cross_val_score`](https://scikit-learn.org/stable/modules/generated/sklearn.model_selection.cross_val_score.html) | `ix_supervised::validation::cross_val_score` |

En IX, los tres implementan el trait [`Classifier`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/traits.rs#L11-L16): `fit(&x, &y)`, `predict(&x)` y `predict_proba(&x)`, con las etiquetas como `Array1<usize>`. El programa es [`examples/l03_classification.rs`](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/examples/l03_classification.rs). Uno de cada cinco jobs es un job de prueba, los demás entrenan: una regla que la comprobación cruzada en Python puede repetir, y que la división aleatoria de IX no puede darle.

```text
== split: train 148 [95, 25, 28], test 38 [26, 9, 3] (ubuntu, windows, macos)
```

## Regresión logística

Una recta da cualquier número; una clase necesita una probabilidad entre 0 y 1. La regresión logística calcula la misma suma ponderada que la lección 2, `z = w·x + b`, y luego la comprime con la **sigmoide** `σ(z) = 1 / (1 + e⁻ᶻ)`: `z = 0` da 0.5, un `z` positivo grande da casi 1. Responde a una pregunta de sí o no; aquí, *¿se ejecuta este job en Windows?*, a partir de `checkout_s` y `post_checkout_s`.

La pérdida ya no es el error cuadrático sino la **log loss** (pérdida logarítmica), que castiga sin límite una respuesta errónea dada con seguridad. Con `pᵢ = σ(w·xᵢ + b)` e `yᵢ` igual a 0 o 1:

```text
L(w, b) = -1/n Σ [ yᵢ·ln(pᵢ) + (1 - yᵢ)·ln(1 - pᵢ) ]
∂L/∂w = 1/n Σ (pᵢ - yᵢ)·xᵢ        ∂L/∂b = 1/n Σ (pᵢ - yᵢ)
```

El gradiente tiene la misma forma que el de la lección 2: predicción menos verdad, por la entrada. No hay forma cerrada; [`src/classify.rs`, líneas 9-31](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/src/classify.rs#L9-L31) da un número fijo de pasos de gradiente desde cero:

```rust
for _ in 0..iterations {
    let mut dw = Array1::<f64>::zeros(p);
    let mut db = 0.0;
    for i in 0..n {
        let error = sigmoid(x.row(i).dot(&w) + b) - y[i] as f64;
        dw.scaled_add(error / n as f64, &x.row(i));
        db += error / n as f64;
    }
    w.scaled_add(-learning_rate, &dw);
    b -= learning_rate * db;
}
```

[`LogisticRegression::fit`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/logistic_regression.rs#L44-L68) hace lo mismo con productos de matrices, y `predict` responde 1 cuando la probabilidad es al menos 0.5:

```text
== logistic regression, windows or not, features ["checkout_s", "post_checkout_s"]
lr 0.01, 1000 iterations: hand w [0.2924, 0.4670] b -1.9327 | ix w [0.2924, 0.4670] b -1.9327 | same to 1e-9: true
  test: accuracy 1.000, windows precision 1.000, recall 1.000
  P(windows | checkout 1 s, post 0.5 s) = 0.197  P(windows | checkout 3 s, post 1.5 s) = 0.412  P(windows | checkout 6 s, post 3 s) = 0.773
lr 0.1, 20000 iterations: hand w [2.4770, 1.8829] b -12.3652 | ix w [2.4770, 1.8829] b -12.3652 | same to 1e-9: true
  test: accuracy 0.974, windows precision 0.900, recall 1.000
  P(windows | checkout 1 s, post 0.5 s) = 0.000  P(windows | checkout 3 s, post 1.5 s) = 0.108  P(windows | checkout 6 s, post 3 s) = 1.000
```

Los mismos números a mano y en IX, pero ¿cuál es *la* regresión logística de estos datos? En las filas de entrenamiento, los jobs de Windows son exactamente los jobs con un checkout de más de 4 segundos (el árbol de decisión de más abajo encuentra esa regla). Con datos separables la log loss no tiene mínimo: sigue bajando a medida que crecen los pesos, y las probabilidades tienden a 0 y 1. IX no tiene criterio de parada ni penalización, así que la respuesta es la que dé el número de iteraciones. Las dos ejecuciones coinciden en casi todos los jobs de prueba, pero no en su grado de seguridad: un job con un checkout de 3 segundos es Windows al 41 % para una, y al 11 % para la otra.

Otras bibliotecas añaden una penalización sobre el tamaño de los pesos, la **regularización**, que da a la pérdida un único mínimo. El valor por defecto de scikit-learn, `C=1`, encuentra `w [2.0809, 0.9997] b -9.8885` en la comprobación cruzada, y un `C=1e6` casi sin penalización encuentra `[6.5664, 2.9888] b -30.3265`; ambos tienen una exactitud de prueba de 0.974. `LbfgsLogisticRegression` de ML.NET también tiene penalizaciones por defecto: `l1Regularization = 1` y `l2Regularization = 1`.

## k vecinos más cercanos

El clasificador más simple no aprende nada: para clasificar un job, busca los `k` jobs de entrenamiento cuyos tiempos son los más cercanos, y toma la clase que tiene la mayoría. «Más cercano» es la distancia euclídea, `√Σ (aⱼ - bⱼ)²` sobre las cinco características ([`src/classify.rs`, líneas 41-68](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/src/classify.rs#L41-L68)):

```rust
let mut near: Vec<(f64, usize)> = x_train
    .rows()
    .into_iter()
    .map(|t| distance(row, t))
    .zip(y_train.iter().copied())
    .collect();
// Una ordenación estable conserva las distancias iguales en el orden de entrenamiento
near.sort_by(|a, b| a.0.total_cmp(&b.0));
let mut votes = vec![0; classes];
for &(_, class) in &near[..k] {
    votes[class] += 1;
}
let best = *votes.iter().max().unwrap();
votes.iter().position(|&v| v == best).unwrap()
```

Las distancias suman segundos de cola a segundos de checkout, así que deciden las características con mayor dispersión. El programa ejecuta `k = 4` y `k = 5` con los tiempos sin escalar, y luego con los tiempos estandarizados con las filas de entrenamiento, como en la lección 1:

```text
== k nearest neighbours, features ["queue_s", "setup_s", "checkout_s", "post_checkout_s", "complete_s"]
raw          k = 4: accuracy hand 0.921, ix 0.921, test rows where they differ: []
raw          k = 5: accuracy hand 0.921, ix 0.921, test rows where they differ: []
standardized k = 4: accuracy hand 0.974, ix 0.947, test rows where they differ: [27]
  test row 27 (jobs.csv row 135, from 0): votes [2, 0, 2] -> hand ubuntu, ix macos, true ubuntu
standardized k = 5: accuracy hand 0.974, ix 0.974, test rows where they differ: []
```

Estandarizar sube la exactitud del 92 % al 97 %. Con `k = 4`, un job de prueba tiene dos vecinos Ubuntu y dos macOS: un empate. La versión a mano da el empate a la primera clase, Ubuntu, y scikit-learn también (exactitud 0.974 en la comprobación cruzada). [`KNN::predict`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/knn.rs#L34-L55) se lo da a macOS:

```rust
votes.iter().enumerate().max_by_key(|(_, &v)| v).unwrap().0
```

[`Iterator::max_by_key`](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.max_by_key) devuelve el **último** de varios máximos iguales, así que IX resuelve cada empate a favor del índice de clase más alto. Ninguna regla es más correcta, pero el resultado pasa a depender del orden de las clases, y difiere del de scikit-learn. Un `k` impar evita los empates entre dos clases, no entre tres: `k = 5` puede votar 2, 2, 1.

ML.NET no tiene entrenador de k vecinos más cercanos en su [lista de entrenadores](https://learn.microsoft.com/dotnet/machine-learning/resources/tasks).

## Árboles de decisión

Un árbol de decisión hace una pregunta sobre una característica en cada nodo, `checkout_s <= 4?`, y envía el job a la izquierda o a la derecha hasta llegar a una hoja, que contiene una clase. Hacerlo crecer es voraz: en cada nodo, prueba cada característica y cada umbral a mitad de camino entre dos valores consecutivos, y quédate con la pregunta que deja los dos grupos más puros.

La pureza se mide con la **impureza de Gini**, la probabilidad de que dos jobs extraídos al azar del grupo (con reemplazo) tengan clases distintas. Con `pₖ` la proporción de la clase `k`:

```text
Gini = 1 - Σ pₖ²                 [10, 0, 0] → 0        [5, 5, 0] → 0.5
gain = Gini(parent) - (nₗ·Gini(left) + nᵣ·Gini(right)) / n
```

La versión a mano es [`src/classify.rs`, líneas 105-160](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/src/classify.rs#L105-L160); la de IX es [`best_split`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/decision_tree.rs#L177-L240), llamada por `build_tree` hasta el límite de profundidad, menos de `min_samples_split` filas (2 por defecto), o un nodo puro ([línea 268](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/decision_tree.rs#L268)). Ambas se quedan con la primera división de mayor ganancia, y ambas envían `<=` a la izquierda. El programa imprime el árbol a mano y luego los nodos guardados de IX:

```text
== decision tree, max depth 3
checkout_s <= 4
  queue_s <= 5.5
    queue_s <= 4.5
      -> ubuntu [89, 0, 0]
    queue_s > 4.5
      -> ubuntu [5, 0, 3]
  queue_s > 5.5
    checkout_s <= 1.5
      -> macos [1, 0, 4]
    checkout_s > 1.5
      -> macos [0, 0, 21]
checkout_s > 4
  -> windows [0, 25, 0]
ix nodes, pre-order: [{"Split":{"feature":2,"threshold":4.0}},{"Split":{"feature":0,"threshold":5.5}},{"Split":{"feature":0,"threshold":4.5}},{"Leaf":{"class":0,"class_counts":[89.0,0.0,0.0]}},{"Leaf":{"class":0,"class_counts":[5.0,0.0,3.0]}},{"Split":{"feature":2,"threshold":1.5}},{"Leaf":{"class":2,"class_counts":[1.0,0.0,4.0]}},{"Leaf":{"class":2,"class_counts":[0.0,0.0,21.0]}},{"Leaf":{"class":1,"class_counts":[0.0,25.0,0.0]}}]
test accuracy hand 0.921, ix 0.921, same predictions: true
confusion matrix (rows = true, columns = predicted):
[[23, 1, 2],
 [0, 9, 0],
 [0, 0, 3]]
ubuntu   precision 1.000 recall 0.885 f1 0.939
windows  precision 0.900 recall 1.000 f1 0.947
macos    precision 0.600 recall 1.000 f1 0.750
```

El mismo árbol tres veces: a mano, en IX y en el `export_text` de scikit-learn en la comprobación cruzada. Se lee como una regla que podrías haber escrito tú: un checkout de más de 4 segundos es Windows; si no, más de 5.5 segundos en la cola es macOS. El árbol encuentra todos los jobs de prueba de Windows y de macOS, y confunde 3 de los 26 jobs de Ubuntu con otra cosa: según sus propias reglas, uno tuvo un checkout de más de 4 segundos, y dos esperaron más de 5.5 segundos en la cola.

Un árbol es el único de los tres modelos que se explica a sí mismo. Su debilidad es la otra cara de eso: si crece lo bastante, hace preguntas hasta que cada job de entrenamiento está en una hoja pura, incluidos los accidentes de esta muestra.

## Validación cruzada

38 jobs de prueba dan una puntuación ruidosa: un job son 2.6 puntos de exactitud. La **validación cruzada de k folds** usa cada fila para prueba una vez: divide las filas en `k` folds, entrena con `k - 1`, prueba con el último, y repite para cada fold. [`cross_val_score`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/validation.rs#L300-L329) toma una closure que construye un modelo nuevo para cada fold, y usa `StratifiedKFold` (ejercicio 2 de la lección 1), así que cada fold conserva la proporción de cada sistema operativo:

```rust
cross_val_score(x, &jobs.os, || DecisionTree::new(3), 5, 42)
```

```text
== cross_val_score, 5 stratified folds, seed 42
knn k=5, raw           folds [0.923, 0.919, 0.973, 1.000, 1.000] mean 0.963
decision tree depth 3  folds [0.923, 0.919, 0.973, 1.000, 0.944] mean 0.952
decision tree depth 10 folds [0.923, 0.892, 0.973, 1.000, 0.917] mean 0.941
```

El árbol más profundo puntúa más bajo: aprende de los folds de entrenamiento reglas que no se cumplen en el fold de prueba, lo que se llama **sobreajuste**. Los folds varían de 0.89 a 1.00, más de lo que los modelos difieren entre sí: con 186 jobs, una diferencia de un punto entre dos modelos significa poco.

`cross_val_score` toma un modelo, no un pipeline: no se le puede pasar un escalador ajustado dentro de cada fold, como exige la lección 1. El ejercicio 2 muestra lo que eso cuesta.

## Puntos clave

- La regresión logística es una recta pasada por una sigmoide, entrenada por descenso de gradiente sobre la log loss. La de IX no tiene regularización ni criterio de parada: con datos casi separables, sus pesos y probabilidades dependen del número de iteraciones.
- Los k vecinos más cercanos necesitan características en la misma escala. IX resuelve los empates de votación a favor del índice de clase más alto, scikit-learn a favor del más bajo.
- Un árbol de decisión elige, en cada nodo, el umbral con la mayor caída de la impureza de Gini. IX, la versión a mano y scikit-learn hacen crecer el mismo árbol con estos datos.
- La validación cruzada da una puntuación por fold: mira su dispersión antes de comparar dos modelos.

## Ejercicios

Las soluciones están en [`examples/l03_exercises.rs`](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/examples/l03_exercises.rs), y su salida en `expected/l03_exercises.txt`.

1. Entrena la regresión logística de IX para responder *macOS o no* a partir de `queue_s` y `checkout_s`, estandarizados con las filas de entrenamiento (tasa de aprendizaje 0.1, 5,000 iteraciones). El modelo predice macOS cuando la probabilidad es al menos 0.5: calcula en su lugar la precisión, la exhaustividad y el F1 para macOS con los umbrales 0.3, 0.5, 0.7 y 0.9, y el `auc_score` de IX.

<details>
<summary>Solución</summary>

[Líneas 18-47](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/examples/l03_exercises.rs#L18-L47):

```rust
let p_mac = model.predict_proba(&x_test).column(1).to_owned();
for threshold in [0.3, 0.5, 0.7, 0.9] {
    let predicted: Array1<usize> = p_mac.mapv(|p| usize::from(p >= threshold));
    let (p, r, f) = precision_recall_f1(&confusion(&y_test, &predicted, 2), 1);
    // …
}
println!("AUC {:.3}", auc_score(&y_test, &p_mac));
```

```text
== exercise 1
weights [4.1125, -0.6938] bias -2.8674
threshold 0.3: macos precision 0.600, recall 1.000, f1 0.750, predicted macos 5
threshold 0.5: macos precision 0.600, recall 1.000, f1 0.750, predicted macos 5
threshold 0.7: macos precision 0.750, recall 1.000, f1 0.857, predicted macos 4
threshold 0.9: macos precision 0.750, recall 1.000, f1 0.857, predicted macos 4
AUC 1.000
```

Un umbral más alto cambia exhaustividad por precisión; aquí, elimina una respuesta macOS errónea sin perder una correcta. El **AUC**, el área bajo la curva ROC ([`metrics.rs`, líneas 480-483](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/metrics.rs#L480-L483)), es la probabilidad de que un job de macOS al azar obtenga una puntuación más alta que otro job al azar, sobre todos los umbrales a la vez. 1.000 dice que los tres jobs de prueba de macOS puntúan por encima de todos los demás jobs: un umbral entre ellos y el cuarto job, en algún punto por encima de 0.9, sería perfecto. El AUC juzga la ordenación; el umbral es una decisión aparte, que se toma según lo que cuesta una falsa alarma comparada con un fallo. Con solo 3 jobs de prueba de macOS, ninguno de estos números es preciso.

</details>

2. Elige `k` para los k vecinos más cercanos: ejecuta `cross_val_score` con 5 folds para `k` de 1 a 15, con las cinco características estandarizadas con las estadísticas de **todas** las filas, e imprime el mejor `k`.

<details>
<summary>Solución</summary>

[Líneas 49-66](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/examples/l03_exercises.rs#L49-L66):

```rust
let z = Scaler::fit(&jobs.features).transform(&jobs.features);
let mut best = (0.0, 0);
for k in 1..=15 {
    let scores = cross_val_score(&z, &jobs.os, || KNN::new(k), 5, 42);
    let mean = scores.iter().sum::<f64>() / 5.0;
    println!("k {k:2}: mean accuracy {mean:.3}");
    if mean > best.0 {
        best = (mean, k);
    }
}
```

```text
== exercise 2
k  1: mean accuracy 0.974
k  2: mean accuracy 0.957
k  3: mean accuracy 0.968
k  4: mean accuracy 0.974
k  5: mean accuracy 0.963
k  6: mean accuracy 0.963
k  7: mean accuracy 0.963
k  8: mean accuracy 0.968
k  9: mean accuracy 0.963
k 10: mean accuracy 0.968
k 11: mean accuracy 0.963
k 12: mean accuracy 0.963
k 13: mean accuracy 0.963
k 14: mean accuracy 0.963
k 15: mean accuracy 0.958
best k 4 (0.974); accuracy of always ubuntu: 0.651
```

`k = 1` y `k = 4` imprimen ambos 0.974; `k = 4` gana en un dígito posterior. De `k = 1` a `k = 15`, las medias se mantienen dentro de 1.7 puntos, unos tres jobs de 186: estos datos no eligen un `k`. Cualquier elección supera a la línea base en al menos 30 puntos.

El escalador ha visto el fold de prueba de cada división, que es la fuga de datos de la lección 1. Con 186 filas del mismo CI, las medias y desviaciones de cuatro quintas partes de las filas se parecen a las de todas las filas, así que el efecto aquí es pequeño, pero una puntuación elegida así es ligeramente optimista. Hacerlo bien significa escribir a mano el bucle de folds, con `StratifiedKFold::split` y un escalador ajustado en cada fold de entrenamiento.

</details>

## Fuentes

- James, Witten, Hastie, Tibshirani, Taylor, *[An Introduction to Statistical Learning](https://www.statlearning.com/)*, capítulos 4 (regresión logística, k vecinos más cercanos), 5 (validación cruzada) y 8 (árboles)
- [scikit-learn: vecinos más cercanos](https://scikit-learn.org/stable/modules/neighbors.html), [árboles de decisión](https://scikit-learn.org/stable/modules/tree.html) y [validación cruzada](https://scikit-learn.org/stable/modules/cross_validation.html)
- IX en `490c395`: [`logistic_regression.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/logistic_regression.rs), [`knn.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/knn.rs), [`decision_tree.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/decision_tree.rs), [`validation.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/validation.rs)
