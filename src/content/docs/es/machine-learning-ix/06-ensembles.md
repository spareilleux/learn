---
title: "6. Conjuntos: bagging, bosques aleatorios y gradient boosting"
description: "Cincuenta árboles poco profundos votando en lugar de un único árbol profundo — muestras bootstrap y la puntuación out-of-bag a mano, un bosque aleatorio que sortea sus variables en cada división frente al único sorteo por árbol de ix_ensemble, el empate que va al mayor índice de clase, y un gradient boosting sobre tocones reproducido hasta el último dígito."
sidebar:
  order: 6
---

El árbol de decisión de la lección 3 llegaba a 0,895 sobre los trabajos de prueba. Hacerlo más profundo ajusta mejor las filas de entrenamiento y peor las de prueba. Los **conjuntos** toman el otro camino: entrenar muchos modelos débiles y combinarlos. Dominan dos recetas, y discrepan en casi todo.

El **bagging** entrena cada modelo sobre una muestra aleatoria distinta de las filas y promedia sus votos. Los modelos son independientes, así que sus errores se cancelan en parte; el conjunto es más estable que cualquiera de sus miembros. El **boosting** entrena los modelos uno tras otro, cada uno corrigiendo lo que fallaron los anteriores. Los modelos son totalmente dependientes, y el conjunto es más afilado pero más fácil de sobreajustar.

| | ML.NET | Tribuo | scikit-learn | IX |
|---|---|---|---|---|
| Bosque aleatorio | [`FastForest`](https://learn.microsoft.com/dotnet/api/microsoft.ml.trainers.fasttree.fastforestbinarytrainer) | [`RandomForestTrainer`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/common/tree/RandomForestTrainer.html) | [`RandomForestClassifier`](https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.RandomForestClassifier.html) | `ix_ensemble::random_forest::RandomForest` |
| Boosting | [`FastTree`](https://learn.microsoft.com/dotnet/api/microsoft.ml.trainers.fasttree.fasttreebinarytrainer), [`LightGbm`](https://learn.microsoft.com/dotnet/api/microsoft.ml.lightgbmextensions) | [`AdaBoostTrainer`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/classification/ensemble/AdaBoostTrainer.html) | [`GradientBoostingClassifier`](https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.GradientBoostingClassifier.html) | `ix_ensemble::gradient_boosting::GradientBoostedClassifier` |
| Puntuación out-of-bag | — | — | `oob_score=True` | — |
| Variables por división | configurable | configurable | `max_features`, resorteadas en cada división | `max_features`, sorteadas una vez por árbol |

El programa es [`examples/l06_ensembles.rs`](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/examples/l06_ensembles.rs), sobre la división de la lección 3: un trabajo de cada cinco para prueba, los otros 148 para entrenamiento.

## El bootstrap

Una **muestra bootstrap** de `n` filas son `n` filas extraídas *con reemplazo*. Algunas llegan dos veces, otras nunca:

```text
== one tree, depth 4: test accuracy 0.8947
a bootstrap of 148 rows drew 100 distinct rows and left 48 out (0.324 of them); 1/e = 0.368
```

Una fila dada escapa a un sorteo con probabilidad `1 - 1/n`, y a los `n` sorteos con probabilidad `(1 - 1/n)ⁿ`, que tiende a `1/e ≈ 0,368` cuando `n` crece. Alrededor de un tercio de las filas nunca llega a un árbol dado — y esas filas son un conjunto de prueba gratis para él. Promediado sobre el bosque, eso es la **puntuación out-of-bag**: cada fila juzgada solo por los árboles que nunca la vieron, sin apartar nada.

IX extrae sus muestras de `rand::rngs::StdRng`, que Python no puede repetir. La versión a mano usa en su lugar un generador xorshift de 64 bits — tres desplazamientos y tres XOR ([`src/ensemble.rs`, líneas 9-31](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/src/ensemble.rs#L9-L31)) — para que la comprobación cruzada reproduzca cada extracción y caiga en las mismas 48 filas:

```rust
pub fn next_u64(&mut self) -> u64 {
    let mut x = self.0;
    x ^= x << 13;
    x ^= x >> 7;
    x ^= x << 17;
    self.0 = x;
    x
}
```

## Bagging, y luego un bosque

El bagging por sí solo da cincuenta árboles que aún se parecen mucho: la división más fuerte — `checkout_s`, que separa Windows del resto — es la primera división de casi todos ellos. El **bosque aleatorio** de Breiman añade una segunda fuente de desacuerdo: en cada nodo solo un puñado aleatorio de variables puede usarse para dividir, de modo que las variables más débiles tienen su turno.

```text
== fifty trees of depth 4, by hand
  bagging, 5 of 5 features: test accuracy 0.8947, out-of-bag accuracy 0.9662
  forest, 3 of 5          : test accuracy 0.9211, out-of-bag accuracy 0.9459
```

El bagging igualó al árbol único; restringir las variables a tres de cinco ganó un trabajo de prueba. IX, con su valor por defecto de `ceil(√5) = 3` variables y otro generador, cae en la misma puntuación:

```text
== ix_ensemble::random_forest::RandomForest::new(50, 4), seed 42
  trees 50, max_features default None -> ceil(sqrt(5)) = 3
  test accuracy 0.9211
```

## Una vez por árbol, o una vez por división

Los dos bosques coinciden aquí, pero no son el mismo algoritmo. El comentario de documentación de `RandomForest` promete «random feature subsets (sqrt(n_features) features per split)»; el código sortea el subconjunto una sola vez, antes de hacer crecer el árbol, y construye todo el árbol únicamente con esas columnas ([`random_forest.rs`, líneas 68-84](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-ensemble/src/random_forest.rs#L68-L84)):

```rust
// Subconjunto aleatorio de variables
let mut all_features: Vec<usize> = (0..p).collect();
for i in 0..max_features {
    let j = rng.random_range(i..p);
    all_features.swap(i, j);
}
let feature_indices: Vec<usize> = all_features[..max_features].to_vec();
// … el árbol se ajusta luego sobre sub_x, que solo tiene esas columnas
```

Con tres variables de cinco la diferencia es pequeña. Lleva `max_features` a 1 y deja de serlo:

```text
== with a single feature
  hand, one feature drawn at every split: 0.9474
  ix, one feature drawn once per tree:    0.7632
```

Sortear una variable *por división* sigue construyendo un árbol de verdad: la raíz puede dividir por `checkout_s`, sus hijos por `queue_s`, los hijos de estos por otra cosa, y el árbol combina las cinco variables a lo largo de cualquier camino. Sortear una variable *por árbol* da cincuenta modelos unidimensionales, cada uno capaz de umbralizar una sola duración, y el voto de cincuenta tocones disfrazados vale 0,763. La versión a mano, con el mismo ajuste nominal, supera al bosque por defecto.

El número que hay que recordar no es 0,7632 sino esto: `max_features` significa algo distinto en `ix-ensemble` que en scikit-learn, Tribuo o el artículo de Breiman, y el comentario de documentación describe el otro sentido.

## El voto, y qué ocurre en un empate

`predict` toma la clase de mayor probabilidad promediada, vía `max_by` ([`random_forest.rs`, línea 97](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-ensemble/src/random_forest.rs#L97)). `Iterator::max_by` devuelve el **último** máximo, así que un empate exacto va al mayor índice de clase. Dos tocones que discrepan fabrican uno:

```text
== a tie between two classes
  two stumps, seed 6: probabilities [0.500, 0.500] -> ix predicts class 1
```

scikit-learn, el bosque a mano y `np.argmax` toman todos el índice menor. Es el mismo comportamiento que la lección 3 encontró en `KNN::predict`, y viene de la misma línea de Rust: en IX un empate se resuelve por el orden de las clases, y las clases se ordenan según lo que el llamante puso en el vector de etiquetas.

Añadir árboles no cambia aquí la puntuación de prueba — los tres trabajos que falla los falla con cualquier tamaño de bosque — pero sí estabiliza la estimación out-of-bag:

```text
== by number of trees (hand forest, 3 of 5)
    1 trees: test 0.9211, out-of-bag 0.9375
    2 trees: test 0.9211, out-of-bag 0.9438
    5 trees: test 0.9211, out-of-bag 0.9323
   10 trees: test 0.9211, out-of-bag 0.9388
   25 trees: test 0.9211, out-of-bag 0.9527
   50 trees: test 0.9211, out-of-bag 0.9459
  100 trees: test 0.9211, out-of-bag 0.9527
```

Más árboles nunca perjudican a un conjunto con bagging — esa es su principal virtud práctica — pero dejan de ayudar, y aquí dejaron de hacerlo antes de que terminara el primero.

## Boosting: ajustar lo que queda

El gradient boosting parte de una constante y añade una pequeña corrección cada vez. Para una clasificación con `K` clases mantiene `K` puntuaciones corrientes por fila. Las puntuaciones iniciales son los log-priores suavizados; en cada ronda, para cada clase, ajusta un **tocón** — un árbol de profundidad 1 — sobre el *residuo* `1{y = c} - p(c)`, la cantidad en que el modelo infravalora ahora esa clase, y añade una copia encogida del tocón a la puntuación.

El residuo es el gradiente negativo de la log-pérdida multiclase respecto a la puntuación, de ahí el nombre: cada ronda es un paso de descenso de gradiente, dado en el espacio de funciones en vez del de parámetros.

Encontrar el tocón es encontrar la división que mejor separa los residuos, es decir la que minimiza el error cuadrático en torno a las dos medias de hoja. Como la suma total de cuadrados no depende de dónde caiga la división, minimizarla equivale a *maximizar* `n_L·mean_L² + n_R·mean_R²`, y eso se barre en una pasada por variable ([`src/ensemble.rs`, líneas 255-265](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/src/ensemble.rs#L255-L265)):

```rust
let left_mean = left_sum / left_n as f64;
let right_mean = (total - left_sum) / right_n as f64;
let score = left_n as f64 * left_mean * left_mean + right_n as f64 * right_mean * right_mean;
```

La versión a mano sigue a `ix_ensemble` paso a paso, incluido el valor de hoja — la media simple de los residuos, donde la receta original de Friedman y scikit-learn usan un paso de Newton. Las dos implementaciones coinciden entonces exactamente:

```text
== gradient boosting on stumps, learning rate 0.3
   1 rounds: hand 0.6842, ix 0.6842, rows where they differ 0
   5 rounds: hand 0.9474, ix 0.9474, rows where they differ 0
  10 rounds: hand 0.9474, ix 0.9474, rows where they differ 0
  25 rounds: hand 0.9211, ix 0.9211, rows where they differ 0
  50 rounds: hand 0.9211, ix 0.9211, rows where they differ 0
```

Ni una fila de 38 difiere, con cualquier número de rondas, y la versión numpy de la comprobación cruzada reproduce las mismas exactitudes. El boosting es el único algoritmo de este curso donde IX, la versión a mano y una tercera implementación coinciden hasta el último dígito — lo que merece decirse con claridad, porque las lecciones hasta ahora han encontrado sobre todo lo contrario.

Cinco rondas ganan a cincuenta. El conjunto llega a un máximo de 0,9474 y baja a 0,9211: sin conjunto reservado ni parada temprana, `n_estimators` es el parámetro que decide si el boosting ayuda, y nada en la API lo mide por ti. El bagging tiene el carácter opuesto — sus árboles de más son inofensivos — que es la razón práctica para recurrir primero a un bosque.

La primera ronda se lee por sí sola:

```text
start, the smoothed log priors: [-0.4529, -1.7592, -1.6500]
  round 1, class ubuntu : split checkout_s <= 1.5, leaves 0.3074 and -0.4358
  round 1, class windows: split checkout_s <= 4.0, leaves -0.1722 and 0.8278
  round 1, class macos  : split queue_s <= 5.5, leaves -0.1671 and 0.7008
  probabilities of the first test job after one round: [0.6682, 0.1567, 0.1751]
```

`exp(-0.4529) = 0,636`: 95 de los 148 trabajos de entrenamiento corrieron en Ubuntu, suavizados sumando uno a cada recuento. El modelo empieza adivinando las tasas base. Luego cada clase recibe la pregunta que más reduce su propio residuo — para Windows, «¿el clonado tardó más de 4 segundos?», para macOS, «¿el trabajo esperó más de 5,5 segundos en la cola?» — y las tres respuestas, pasadas por softmax, ya colocan el primer trabajo de prueba en Ubuntu con probabilidad 0,67.

## Puntos clave

- Una muestra bootstrap de `n` filas deja fuera aproximadamente un tercio, `1/e` a medida que `n` crece, y esas filas dan a cada árbol una prueba out-of-bag gratuita.
- Un bosque aleatorio añade al bagging subconjuntos aleatorios de características. scikit-learn, Tribuo y Breiman los vuelven a sortear en cada división; `ix_ensemble` los sortea una vez por árbol, lo que con una sola característica hace caer la exactitud de prueba de 0.9474 a 0.7632.
- El bosque de IX resuelve un empate exacto a favor del mayor índice de clase, mientras que scikit-learn toma el menor.
- Más árboles nunca perjudican a un ensamble de bagging, pero dejan de ayudar: aquí la puntuación de prueba no se movió después del primer árbol.
- El gradient boosting ajusta cada tocón a los residuos de la pérdida logarítmica. La versión a mano, IX y numpy coinciden hasta el último dígito, y la puntuación alcanza su máximo en 5 rondas, así que el número de rondas necesita una comprobación con datos reservados.

## Ejercicios

1. ¿Sigue la puntuación out-of-bag a la de prueba cuando los árboles se hacen más profundos?
2. ¿Dónde discrepan los dos bosques sobre el conjunto de prueba, y qué filas sigue fallando el bosque?
3. ¿Qué sistemas operativos confunde el bosque?

<details>
<summary>Soluciones</summary>

Están en [`examples/l06_exercises.rs`](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/examples/l06_exercises.rs).

**1.** Sigue su *forma* pero no su nivel:

```text
== depth against the two scores (hand forest, 50 trees, 3 of 5 features)
  depth 1: out-of-bag 0.7838, test 0.9211
  depth 2: out-of-bag 0.9730, test 0.9211
  depth 3: out-of-bag 0.9730, test 0.9211
  depth 4: out-of-bag 0.9459, test 0.9211
  depth 5: out-of-bag 0.9662, test 0.9211
  depth 6: out-of-bag 0.9595, test 0.9211
  depth 7: out-of-bag 0.9595, test 0.9211
  depth 8: out-of-bag 0.9595, test 0.9211
```

La profundidad 1 es claramente insuficiente, y ambas puntuaciones lo dicen. Después la puntuación out-of-bag vaga entre 0,946 y 0,973 mientras la de prueba no se mueve en absoluto. Con 148 filas de entrenamiento, una estimación out-of-bag descansa sobre unas 54 de ellas por árbol, y diferencias de 0,02 son ruido. Es una alarma útil para «este modelo está gravemente mal», no una forma de elegir entre dos profundidades razonables.

**2.** Nunca discrepan, y ambos fallan en los mismos tres trabajos:

```text
== the two forests on the 38 test jobs
  hand 0.9211, ix 0.9211, rows where they disagree: []
  the rows the hand forest still gets wrong:
    test job 12, workflow Deploy to GitHub Pages         truly ubuntu  predicted macos
    test job 27, workflow Rust course examples           truly ubuntu  predicted macos
    test job 29, workflow GHA 05: caches and artifacts   truly ubuntu  predicted windows
```

Los tres son trabajos de Ubuntu que se comportaron como otra cosa — una cola lenta o un clonado lento en un runner normalmente rápido. Nada en cinco duraciones distingue un trabajo Ubuntu lento de uno macOS normal, así que ninguna cantidad de árboles los recuperará; el techo aquí son los datos, no el modelo.

**3.** Todos los errores son trabajos de Ubuntu llamados de otra forma:

```text
== confusion of the hand forest, rows true, columns predicted
  order ["ubuntu", "windows", "macos"]
  ubuntu  [23, 1, 2]
  windows [0, 9, 0]
  macos   [0, 0, 3]
```

Windows y macOS se reconocen a la perfección. Esto es lo que hace un conjunto de entrenamiento desequilibrado: con 121 trabajos de Ubuntu frente a 34 y 31, la clase mayoritaria absorbe la incertidumbre, y los errores caen todos sobre ella.

</details>

## Fuentes

- Breiman, *[Random Forests](https://link.springer.com/article/10.1023/A:1010933404324)*, 2001, para el bagging, el sorteo de variables en cada división y la estimación out-of-bag
- Friedman, *[Greedy Function Approximation: A Gradient Boosting Machine](https://projecteuclid.org/euclid.aos/1013203451)*, 2001
- James, Witten, Hastie, Tibshirani, Taylor, *[An Introduction to Statistical Learning](https://www.statlearning.com/)*, capítulo 8
- [scikit-learn: métodos de conjunto](https://scikit-learn.org/stable/modules/ensemble.html)
- IX en `490c395`: [`ix-ensemble/src/random_forest.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-ensemble/src/random_forest.rs), [`ix-ensemble/src/gradient_boosting.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-ensemble/src/gradient_boosting.rs)
