---
title: "9. Otros cinco reductores: MDS, ACP con núcleo, NMF, LDA y t-SNE"
description: "Reconstruir un cuadrado a partir de distancias a mano y con IX, encontrar el eje que distingue dos anillos, factorizar tiempos de CI, proyectar jobs etiquetados y comprobar qué hace realmente transform en el t-SNE de IX."
sidebar:
  order: 9
---

La lección 5 usó el [ACP](../05-dimensionality-reduction/) para conservar las direcciones de mayor varianza. Esa es solo una pregunta, no una definición universal de proyección útil. Aquí hay otras cinco preguntas, cada una atendida por un reductor del [`ix-unsupervised`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised) fijado. El experimento ejecutable está en [`l09_reducers.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/examples/l09_reducers.rs); [`crosscheck.py`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/crosscheck/crosscheck.py) comprueba las mismas propiedades de forma independiente con numpy y scikit-learn 1.8.0. El [diario](../journal/#2026-09-24--cinco-reductores-tres-entradas) distingue mediciones de incertidumbres.

| Pregunta | Método | Entrada | Significado de la salida |
|---|---|---|---|
| ¿Se pueden preservar distancias sin conocer siquiera las características? | MDS clásico | Matriz de distancias por pares | Coordenadas que reproducen distancias euclidianas, cuando es posible |
| ¿Revela una similitud no lineal una estructura que un eje recto oculta? | ACP con núcleo | Características y núcleo elegido | Ejes de varianza en el espacio del núcleo |
| ¿Se pueden expresar mediciones positivas como partes aditivas? | NMF | Matriz de características no negativas | Dos factores no negativos cuyo producto aproxima la entrada |
| ¿Qué direcciones separan clases **conocidas**? | Análisis discriminante lineal (LDA) | Características **y** etiquetas | Como máximo `clases - 1` ejes discriminantes |
| ¿Qué puntos son vecinos en una visualización? | t-SNE | Matriz de características | Disposición ajustada; distancias y tamaños aparentes de grupos no son mediciones calibradas |

Aquí **LDA** significa *análisis discriminante lineal*, no el método distinto llamado *latent Dirichlet allocation*. Ninguna de estas proyecciones sustituye una evaluación sobre datos reservados.

## 1. MDS: partir de las distancias, no de las características

El [escalado multidimensional clásico](https://scikit-learn.org/stable/modules/manifold.html#multidimensional-scaling) parte de una matriz `D` de tamaño `n × n`, no de las características originales. Elevamos cada distancia al cuadrado, restamos las medias de su fila y columna y sumamos la media global:

```text
Bᵢⱼ = -½ (D²ᵢⱼ - row_meanᵢ - column_meanⱼ + grand_mean)
```

Es la identidad `B = -½ J D² J`, con `J = I - 11ᵀ/n`. Si las distancias proceden de puntos euclidianos, `B` es su matriz de Gram centrada: los principales autovectores, multiplicados por las raíces cuadradas de sus autovalores, dan coordenadas. La versión a mano reutiliza el algoritmo de Jacobi de la lección 5; [`classical_mds`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/mds.rs) usa el solucionador simétrico de `ix-math`. En un cuadrado de lado uno, ambas recuperan las seis distancias no nulas con un error inferior a `1e-10`:

```text
== classical MDS: square from distances alone
  hand and IX recover all six distances: true
```

Comparamos *distancias*, no coordenadas: una rotación o reflexión cambia las coordenadas sin cambiar la respuesta. Una matriz de distancias no euclidianas puede tener autovalores negativos; truncarlos a cero produce una aproximación, no demuestra que las distancias originales tengan una representación exacta. IX implementa aquí MDS **clásico**, no minimización iterativa del *stress*.

## 2. ACP con núcleo: una similitud no lineal es una elección

El [ACP con núcleo](https://scikit-learn.org/stable/modules/decomposition.html#kernel-pca) sustituye la matriz de covarianza del ACP por una matriz de núcleo centrada, `Kᵢⱼ = k(xᵢ, xⱼ)`. El [`Kernel`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/kernel_pca.rs) de IX es una enumeración con variantes lineal, polinómica y gaussiana RBF. Su valor RBF es `exp(-γ ||xᵢ-xⱼ||²)`: `γ` cambia qué separaciones cuentan como cercanas.

Ocho puntos forman dos anillos concéntricos. Cada anillo tiene media `(0, 0)`, así que un primer eje **lineal** no puede separar sus medias. La expectativa exploratoria de que el **primer eje RBF** sí lo haría también fue falsa. Con `γ = 0.5`, el contraste radial aparece en el **eje 4**:

```text
== kernel PCA: concentric rings
  mean gap on linear axis: 0.0000
  mean gap on RBF axis 1: 0.0000
  mean gap on RBF axis 4: 0.5798
  linear axis separates ring means: false
  fourth RBF axis separates ring means: true
```

Conservar solo las dos primeras componentes perdería la propiedad buscada. No es un defecto de IX: maximizar la varianza en el espacio del núcleo sigue sin ser el mismo objetivo que separar los anillos. Los signos de los ejes son arbitrarios; el experimento usa la diferencia absoluta entre las medias de ambos anillos.

## 3. NMF: las partes aditivas exigen datos no negativos

La [factorización matricial no negativa](https://scikit-learn.org/stable/modules/decomposition.html#nmf) busca `V ≈ W H` con todas las entradas de `V`, `W` y `H` no negativas. [`NonNegativeMatrixFactorization`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/nmf.rs) de IX usa actualizaciones multiplicativas. Los 186 jobs de CI del curso tienen cinco tiempos no negativos en segundos: son una entrada válida. Con rango dos, 300 iteraciones y semilla 42, el error cuadrático medio de reconstrucción es `0.505` segundos cuadrados por celda:

```text
== NMF: CI timings, 186 jobs x 5 features
  rank 2 reconstruction MSE: 0.505
  standardized input rejected: true
```

Estandarizar esas mismas columnas resta su media y crea valores negativos: IX rechaza la matriz. Usemos los tiempos originales para NMF, pero no llamemos a los dos factores «arquetipos de carga» solo por el error de reconstrucción. Hay que comparar semillas, inspeccionar `H` y probar la reconstrucción con datos reservados. A diferencia del ACP, NMF no es una proyección ortogonal y sus factores no son únicos.

## 4. LDA: las etiquetas deciden qué importa

El [análisis discriminante lineal](https://scikit-learn.org/stable/modules/lda_qda.html#dimensionality-reduction-using-linear-discriminant-analysis) contrapone la dispersión entre clases con la dispersión dentro de cada clase. Conocemos el sistema operativo del runner de cada job: Ubuntu, Windows o macOS. [`LinearDiscriminantAnalysis`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/lda.rs) de IX ajusta dos ejes a los tiempos estandarizados:

```text
== LDA: runner OS labels
  three OS classes allow at most two axes: true
  projection finite: true
```

Tres clases permiten como máximo `3 - 1 = 2` ejes discriminantes, aunque la entrada tenga cinco columnas. El ejemplo ajusta y proyecta las **mismas** 186 filas para enseñar la API; no presenta exactitud de test. Para probar si los tiempos predicen el SO, primero hay que separar entrenamiento y test, ajustar el escalador y LDA solo con entrenamiento, transformar el test y después entrenar y evaluar un clasificador. De lo contrario, las etiquetas del test se filtran a la proyección.

## 5. t-SNE: un dibujo de vecindarios, no un escalador reutilizable

[t-SNE](https://scikit-learn.org/stable/modules/manifold.html#t-sne) convierte distancias en probabilidades de vecindad en los datos de entrada y en una disposición de baja dimensión; luego mueve los puntos para reducir la diferencia. La *perplejidad* determina una escala de vecindad, no el número de grupos. La gráfica puede sugerir preguntas útiles, pero sus distancias globales y los tamaños aparentes de los grupos no son mediciones calibradas.

[`TSNE`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/tsne.rs) de IX acepta una semilla. Ajustamos doce jobs estandarizados, con perplejidad 3 y 300 iteraciones. La cabecera del módulo promete una «aproximación Barnes-Hut», pero esta versión recorre todos los pares en `compute_q` y otra vez en el gradiente: presupuestemos trabajo cuadrático, no el escalado de Barnes-Hut. Además, `transform` ignora su argumento y devuelve la disposición ya ajustada:

```text
== t-SNE: first 12 standardized jobs
  12 x 2 finite embedding: true
  transform ignores its input: true
```

Pasar un decimotercer job a `transform` **no** lo sitúa en el mapa. Volver a ajustar con ese punto cambia el problema y puede mover todos los puntos. Si hay que proyectar futuros jobs, empecemos por ACP o ACP con núcleo ajustado; el t-SNE de IX no sirve como transformador de producción.

## ¿Qué usar en nuestros repositorios?

- **Geometría de voicings en IX/GA:** empezar por ACP y una métrica de búsqueda musical adecuada; usar ACP con núcleo o t-SNE como vistas exploratorias, nunca como prueba de que las islas visuales son clases musicales.
- **Historia de Gaia o CI:** MDS clásico tiene sentido cuando el objeto es una distancia medida entre ejecuciones o trazas, no un vector numérico. Comprobar que las distancias son euclidianas antes de prometer un mapa exacto.
- **Tiempos de CI:** NMF podría revelar patrones aditivos, pero exige comprobar estabilidad y reconstrucción fuera de muestra. LDA plantea otra pregunta, supervisada, usando las etiquetas de runner.

## Ejercicios

1. ¿Por qué comparar las seis distancias del cuadrado y no cuatro pares de coordenadas? ¿Qué implicaría un error máximo de `0.2`?
2. ¿Por qué la primera componente RBF no separa los anillos y la cuarta sí? ¿Qué pasa al conservar solo dos componentes?
3. ¿Por qué NMF rechaza los jobs estandarizados? ¿Qué debe ajustarse solo con las filas de entrenamiento antes de estimar si las coordenadas LDA predicen el SO?
4. ¿Puede el t-SNE de IX situar un job nuevo con `transform`? ¿Qué línea de su código fijado resuelve la cuestión?

<details>
<summary>Soluciones</summary>

1. Ni el signo ni la orientación de los autovectores son únicos; las distancias por pares sí. Un error de `0.2` significa que esta representación bidimensional **no** reproduce exactamente la geometría solicitada.
2. Los primeros ejes maximizan la varianza en el espacio del núcleo, no la separación de anillos; aquí el contraste radial es el cuarto. Dos componentes lo pierden. Cambiar `γ` o los datos puede cambiar el orden: hay que inspeccionar los ejes ajustados.
3. El centrado crea entradas negativas, prohibidas por NMF. Para una estimación supervisada, separar antes de ajustar tanto el escalador como LDA y evaluar sobre el test intacto.
4. No. En la [implementación de `DimensionReducer`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/tsne.rs#L249-L253), `fn transform(&self, _x: &Array2<f64>)` devuelve `self.embedding.clone()`; `_x` no se lee.

</details>

## Fuentes

- IX en el commit fijado `490c395`: [MDS](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/mds.rs), [ACP con núcleo](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/kernel_pca.rs), [NMF](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/nmf.rs), [LDA](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/lda.rs), [t-SNE](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/tsne.rs).
- [Guía de scikit-learn sobre variedades](https://scikit-learn.org/stable/modules/manifold.html), [guía sobre descomposiciones](https://scikit-learn.org/stable/modules/decomposition.html) y [guía de LDA](https://scikit-learn.org/stable/modules/lda_qda.html).
