---
title: "5. Componentes principales, y qué significa una razón de varianza"
description: "Cinco duraciones de integración continua reducidas a dos, diagonalizando su matriz de covarianza — las rotaciones de Jacobi a mano frente a la iteración de potencia de IX, la razón de varianza explicada que IX normaliza sobre las componentes retenidas en lugar de sobre los datos, y una nube cuyo eje principal se le escapa a la iteración de potencia porque su vector inicial le es ortogonal."
sidebar:
  order: 5
---

Las lecciones 3 y 4 trabajaban sobre los mismos cinco números: los segundos que un trabajo de integración continua pasa esperando, preparándose, clonando, limpiando y terminando. Cinco números ya son demasiados para dibujar, y dos de ellos — `checkout_s` y `post_checkout_s` — llevan casi la misma información. La **reducción de dimensión** pide menos números que pierdan lo menos posible.

La respuesta más antigua es el **análisis de componentes principales**: encontrar la dirección a lo largo de la cual los datos varían más, luego la dirección de mayor variación restante perpendicular a la primera, y así sucesivamente. Quédate con las dos primeras y podrás dibujar los datos; quédate con todas y solo los habrás rotado.

| | ML.NET | Tribuo | scikit-learn | IX |
|---|---|---|---|---|
| ACP | [`ProjectToPrincipalComponents`](https://learn.microsoft.com/dotnet/api/microsoft.ml.pcacatalog.projecttoprincipalcomponents) | [`PCA`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/util/infotheory/example/package-summary.html) vía `TransformationMap` | [`PCA`](https://scikit-learn.org/stable/modules/generated/sklearn.decomposition.PCA.html) | `ix_unsupervised::pca::PCA` |
| Cómo se hallan los ejes | SVD aleatorizada | SVD | SVD, `svd_flip` para los signos | iteración de potencia con deflación |
| Varianza explicada | `Eigenvalues` | — | `explained_variance_ratio_` | `explained_variance_ratio()` |
| Los demás del crate | — | — | `KernelPCA`, `NMF`, `TSNE`, `MDS`, `LDA` | `kernel_pca`, `nmf`, `tsne`, `mds`, `lda` |

El programa de esta lección es [`examples/l05_reduction.rs`](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/examples/l05_reduction.rs). Trabaja sobre los 186 trabajos, estandarizados como en la lección 4, para que un segundo de espera cuente tanto como un segundo de clonado.

## La varianza a lo largo de una dirección

Toma un vector unitario **u**. Proyecta sobre él cada fila centrada: las proyecciones tienen una varianza. Escrita con la **matriz de covarianza** **C** — aquella cuya entrada `i, j` es la covarianza de la variable `i` con la variable `j` — esa varianza es exactamente `uᵀ C u`.

Así que «la dirección de mayor varianza» es «el vector unitario que maximiza `uᵀ C u`», y el álgebra lineal responde en una línea: es el **vector propio** de **C** asociado al mayor **valor propio**, y ese valor propio *es* la varianza a lo largo de ese eje. La segunda dirección es el siguiente vector propio, la tercera el siguiente, y como **C** es simétrica todos son perpendiculares entre sí.

Las columnas estandarizadas hacen **C** fácil de leer: cada entrada de la diagonal vale 1, y todas las demás son correlaciones.

```text
== covariance matrix of the standardized features
  [1.005, -0.083, 0.048, 0.030, 0.516]
  [-0.083, 1.005, -0.201, -0.276, 0.095]
  [0.048, -0.201, 1.005, 0.794, 0.084]
  [0.030, -0.276, 0.794, 1.005, 0.040]
  [0.516, 0.095, 0.084, 0.040, 1.005]
trace (total variance): 5.027
```

La diagonal vale 1,005 en lugar de 1 porque la estandarización divide por `n` y la covarianza por `n - 1`. Destacan dos pares: `checkout_s` con `post_checkout_s` a 0,794 — limpiar un clon lleva tanto tiempo como el clon merecía — y `queue_s` con `complete_s` a 0,516. Cinco variables, pero menos de cinco cosas independientes en juego.

## Dos formas de diagonalizar

IX halla un vector propio cada vez mediante **iteración de potencia**: multiplicar un vector inicial por **C** una y otra vez, y este gira hacia el vector propio de mayor valor propio. Luego IX **deflaciona** — resta ese par propio de la matriz — y vuelve a empezar ([`pca.rs`, líneas 103-151](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/pca.rs#L103-L151)):

```rust
let mut v = Array1::from_elem(n, 1.0 / (n as f64).sqrt());
// …
let v_new = matrix.dot(&v);
let new_eigenvalue = v.dot(&v_new);
```

Esta lección emplea el otro método clásico, el de **Jacobi**: elegir repetidamente la mayor entrada fuera de la diagonal y anularla con una rotación. Cada rotación es un cambio de base que conserva los valores propios; cuando ya no queda nada fuera de la diagonal, la diagonal lleva todos los valores propios y las rotaciones acumuladas todos los vectores propios ([`src/reduce.rs`, líneas 34-93](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/src/reduce.rs#L34-L93)):

```rust
// El ángulo que anula m[p][q]: cot(2θ) = (m[p][p] - m[q][q]) / (2 m[p][q])
let theta = 0.5 * (2.0 * m[[p, q]]).atan2(m[[p, p]] - m[[q, q]]);
let (c, s) = (theta.cos(), theta.sin());
```

Un vector propio no tiene signo natural: **u** y **-u** describen el mismo eje. scikit-learn lo resuelve haciendo positiva la entrada de mayor valor absoluto de cada componente, y la versión a mano copia esa regla para que ambas se comparen entrada por entrada.

```text
== all five components, by hand (Jacobi)
  component 1: variance 1.9441, ratio 0.3867, cumulative 0.3867, [0.161, -0.331, 0.645, 0.654, 0.140]
  component 2: variance 1.5060, ratio 0.2996, cumulative 0.6863, [0.679, 0.142, -0.102, -0.144, 0.699]
  component 3: variance 0.9183, ratio 0.1827, cumulative 0.8690, [-0.251, 0.891, 0.291, 0.194, 0.146]
  component 4: variance 0.4517, ratio 0.0899, cumulative 0.9588, [-0.671, -0.269, -0.063, -0.057, 0.686]
  component 5: variance 0.2070, ratio 0.0412, cumulative 1.0000, [0.005, 0.069, -0.696, 0.714, 0.027]
sum of the five ratios: 1.0000
```

La primera componente es `0.645 · checkout_s + 0.654 · post_checkout_s` con pequeñas contribuciones del resto: el eje del clonado, exactamente el par correlacionado a 0,794. La segunda es `0.679 · queue_s + 0.699 · complete_s`: el eje de la espera. Dos ejes de cinco explican el 69 % de todo lo que hacen las cinco duraciones.

Los cinco valores propios suman 5,027, la traza de la matriz de covarianza. No es casualidad: rotar los datos no puede crear ni destruir varianza, solo repartirla entre los ejes.

## IX encuentra los mismos ejes

```text
== ix_unsupervised::pca::PCA, five components
  ix   variance [1.9441, 1.5060, 0.9183, 0.4517, 0.2070]
  hand variance [1.9441, 1.5060, 0.9183, 0.4517, 0.2070]
  largest difference: 1.28e-10
  component 1: ix [0.161, -0.331, 0.645, 0.654, 0.140] same direction as the hand version
  component 2: ix [0.679, 0.142, -0.102, -0.144, 0.699] same direction as the hand version
  component 3: ix [-0.251, 0.891, 0.291, 0.194, 0.146] same direction as the hand version
  component 4: ix [0.671, 0.269, 0.063, 0.057, -0.686] opposite direction to the hand version
  component 5: ix [0.005, 0.069, -0.696, 0.714, 0.027] same direction as the hand version
```

Las varianzas coinciden hasta diez decimales, y scikit-learn imprime las mismas cinco. La componente 4 apunta en sentido contrario, lo que no cambia ni el subespacio ni la reconstrucción — la iteración de potencia simplemente no tiene convención de signo, y el sentido del vector inicial decide el sentido de la respuesta. Un código que compare dos ejecuciones de un ACP debe comparar ejes, no vectores.

Las puntuaciones también coinciden, ya que el signo de la componente 4 no entra en las dos primeras:

```text
== first three jobs in two dimensions
  job 0 on ubuntu  hand [-1.2345, 1.7418] ix [-1.2345, 1.7418]
  job 1 on ubuntu  hand [-1.9498, -0.1172] ix [-1.9498, -0.1172]
  job 2 on ubuntu  hand [-0.5102, -0.6465] ix [-0.5102, -0.6465]
```

## La razón que siempre vale 1

Pide dos componentes en lugar de cinco y las dos bibliotecas dejan de estar de acuerdo:

```text
== keeping two of the five components
  hand ratio [0.3867, 0.2996] sum 0.6863
  ix   ratio [0.5635, 0.4365] sum 1.0000
```

`explained_variance_ratio` divide cada valor propio retenido por la suma de los valores propios **retenidos** ([`pca.rs`, líneas 46-57](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/pca.rs#L46-L57)):

```rust
self.explained_variance.as_ref().map(|ev| {
    let total = ev.sum();
    if total > 0.0 { ev / total } else { ev.clone() }
})
```

`ev` solo contiene las `n_components` valores propios que el modelo ha guardado: las razones suman 1 pidas lo que pidas, y el comentario de documentación — «proportion of total variance per component» — solo es cierto si guardas todas las componentes. El número que quiere un lector es 0,3867: la parte de la varianza *de los datos*. IX informa de 0,5635, la parte de lo que ha decidido guardar, que no sirve para decidir cuánto guardar. El ejercicio de abajo muestra la consecuencia: la pregunta habitual «¿cuántas componentes para el 90 %?» siempre responde «una».

Las varianzas en bruto lo resolverían, pero `explained_variance` es un campo privado; `save_state()` es la única forma de leerlas desde un modelo ajustado.

:::note[Confirmado de forma independiente]
`PCA(n_components=2)` de scikit-learn sobre la misma matriz informa de `[0.3867, 0.2996]`, con suma 0,6863 — la versión a mano, no la de IX. Véase la sección `== lesson 5` de [`crosscheck/crosscheck.py`](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/crosscheck/crosscheck.py).
:::

## Lo que se pierde

Quedarse con `k` componentes y luego volver atrás da la mejor aproximación de rango `k` de los datos. El error que deja es exactamente la varianza desechada:

```text
== mean squared reconstruction error, and the variance kept
  k 1: error 0.6133, variance kept 0.3867
  k 2: error 0.3137, variance kept 0.6863
  k 3: error 0.1310, variance kept 0.8690
  k 4: error 0.0412, variance kept 0.9588
  k 5: error 0.0000, variance kept 1.0000
```

Las dos columnas suman 1,0000 en cada fila, y no por suerte: unas variables estandarizadas tienen un cuadrado medio de 1 por celda, así que el error que dejan `k` componentes es exactamente la parte de varianza que llevaban las demás. Esa identidad es la razón por la que la razón importa — es el único número que dice lo que cuesta una reducción, que es también por lo que una razón que siempre muestra 1,0000 no dice nada.

## Una nube que la iteración de potencia no puede ver

La iteración de potencia parte siempre del mismo vector — `(1, 1, …, 1)/√n`, con todas las coordenadas iguales ([`pca.rs`, línea 107](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/pca.rs#L107)). Multiplicar por **C** gira ese vector hacia el vector propio dominante — salvo que ya sea él mismo un vector propio, en cuyo caso nunca se mueve.

Seis puntos forman una nube así. Se estiran a lo largo de `(1, -1)`, con algo de dispersión según `(1, 1)`:

```text
== a cloud stretched along (1, -1)
  covariance [2.4, -1.6, -1.6, 2.4]
  hand eigenvalues [4.0000, 0.8000] first eigenvector [0.7071, -0.7071]
  ix PCA(1): variance [0.8000] component [0.7071, 0.7071]
  ix PCA(2): variance [0.8000, 0.0000] components [0.7071, 0.7071] [0.7071, 0.7071]
  ix PCA(1) scores [0.0000, 0.0000, 0.0000, 0.0000, 1.4142, -1.4142]
```

El eje principal lleva una varianza de 4,0 a lo largo de `(1, -1)`. `PCA::new(1)` devuelve el otro: varianza 0,8 a lo largo de `(1, 1)`, el eje *menor*. El vector inicial es ese vector propio menor, así que `C·v = 0,8·v`, el cociente de Rayleigh deja de cambiar ya en la segunda pasada, y el bucle sale satisfecho.

`PCA::new(2)` lo hace peor. La deflación retira el eje 0,8 y deja una matriz cuya única dirección es `(1, -1)`; la iteración de potencia arranca de nuevo desde `(1, 1)/√2`, que esa matriz envía a cero, salta la protección `norm < 1e-15`, y el vector inicial se devuelve sin cambios. El modelo acaba con la misma componente dos veces y una varianza de 0, describiendo una nube bidimensional con un solo eje repetido.

Las puntuaciones muestran el coste: cuatro de los seis puntos se proyectan exactamente en 0, así que la reducción que debía conservar la dirección más informativa ha aplanado los datos justo en ella.

Es un caso al filo de la navaja — hacen falta dos variables con exactamente la misma varianza — y sobre los trabajos de integración continua IX y Jacobi coinciden hasta diez decimales. Pero lo que importa es la forma del fallo, no su rareza: la iteración de potencia desde un inicio fijo no ofrece garantía alguna, y nada en la salida de `PCA` dice en qué caso estás. La SVD de scikit-learn no tiene vector inicial, y devuelve una varianza de 4,0 a lo largo de `(0.7071, -0.7071)`.

## Qué hacer con esto

- Para decidir cuántas componentes guardar, calcula tú mismo la razón a partir de `save_state().explained_variance`, dividiendo por la suma sobre *todas* las componentes — lo que significa ajustar una vez `PCA::new(n_features)`.
- Antes de fiarte de una primera componente, ajusta con todas las componentes y comprueba que las varianzas salen en orden decreciente. La iteración de potencia seguida de deflación no puede garantizarlo, y la herramienta `ix_ml_pipeline` activa el ACP con `normalize`.
- Comparar dos ejecuciones de un ACP es comparar subespacios o valores absolutos, nunca vectores con signo.

## Ejercicios

1. ¿Cuántas componentes hacen falta para conservar el 90 % de la varianza, y qué dice `explained_variance_ratio()` para cada número?
2. **Blanquea** las puntuaciones de dos componentes — divide cada columna por su propia desviación típica — y muestra que el resultado tiene matriz de covarianza identidad.
3. Reconstruye el trabajo 0 a partir de 1, 2, 3, 4 y luego 5 componentes y obsérvalo converger a la fila verdadera.

<details>
<summary>Soluciones</summary>

Están en [`examples/l05_exercises.rs`](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/examples/l05_exercises.rs).

**1.** Hacen falta cuatro. IX responde a la pregunta con 1,0000 pidas lo que pidas, así que la pregunta no se le puede hacer:

```text
== components needed for a share of the variance
  k 1: really kept 0.3867, ix reports 1.0000
  k 2: really kept 0.6863, ix reports 1.0000
  k 3: really kept 0.8690, ix reports 1.0000
  k 4: really kept 0.9588, ix reports 1.0000
  k 5: really kept 1.0000, ix reports 1.0000
  4 components pass 0.90; IX reports 1.0000 for every k
```

**2.** Las puntuaciones ya están descorrelacionadas — es lo que compra la perpendicularidad — así que su matriz de covarianza es diagonal y lleva los dos valores propios. Dividir cada columna por la raíz de su valor propio pone ambas varianzas a 1:

```text
== whitening the two-component scores
  covariance of the raw scores
    [1.944062, 0.000000]
    [0.000000, 1.505963]
  covariance of the whitened scores
    [1.000000, 0.000000]
    [0.000000, 1.000000]
```

El blanqueo es lo que quiere un método basado en distancias antes de empezar: tras él, la distancia euclídea en el espacio de puntuaciones es la distancia de Mahalanobis en el espacio original.

**3.** Una componente coloca el trabajo 0 cerca del medio de todo; la quinta lo restituye exactamente:

```text
== job 0 rebuilt, one component at a time
  true      [-0.091, 1.785, -0.596, -0.796, 1.968]
  k 1       [-0.198, 0.409, -0.797, -0.808, -0.173]
  k 2       [0.984, 0.655, -0.975, -1.059, 1.043]
  k 3       [0.589, 2.056, -0.517, -0.754, 1.273]
  k 4       [-0.091, 1.783, -0.581, -0.811, 1.968]
  k 5       [-0.091, 1.785, -0.596, -0.796, 1.968]
```

El trabajo 0 es inusual — 1,785 desviaciones típicas de preparación y 1,968 de finalización — así que la primera componente, que habla de clonado, se equivoca con él; es la tercera, el eje de la preparación, la que lo recupera.

## Fuentes

- James, Witten, Hastie, Tibshirani, Taylor, *[An Introduction to Statistical Learning](https://www.statlearning.com/)*, capítulo 12
- Golub y Van Loan, *Matrix Computations*, capítulo 8, para el método de Jacobi y la convergencia de la iteración de potencia
- [scikit-learn: descomposición en componentes](https://scikit-learn.org/stable/modules/decomposition.html) y [`svd_flip`](https://scikit-learn.org/stable/modules/generated/sklearn.utils.extmath.svd_flip.html)
- IX en `490c395`: [`ix-unsupervised/src/pca.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/pca.rs), y los demás reductores del mismo crate — [`tsne.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/tsne.rs), [`mds.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/mds.rs), [`kernel_pca.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/kernel_pca.rs), [`nmf.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/nmf.rs), [`lda.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/lda.rs)

</details>
