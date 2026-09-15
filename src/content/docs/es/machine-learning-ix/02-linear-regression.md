---
title: 2. Regresión lineal y descenso de gradiente
description: Una recta a través de los tiempos de build de este sitio, por mínimos cuadrados en forma cerrada y por descenso de gradiente — a mano, con la ecuación normal de IX y con los optimizadores SGD, Momentum y Adam de IX —, por qué el descenso diverge con características sin escalar, qué cambia al estandarizar, y un valor atípico que decide la pendiente.
sidebar:
  order: 2
---

La lección 1 predijo cada build con una constante. Esta lección deja que la predicción dependa de una característica, el número de páginas, siguiendo el modelo más antiguo que existe: una recta, `seconds = w · pages + b`. Encontrar `w` y `b` es la **regresión lineal**. Se puede resolver exactamente, con una fórmula, o paso a paso, con **descenso de gradiente**; la segunda vía es como se entrena casi cualquier otro modelo de aprendizaje automático, así que vale la pena verla en un problema cuya respuesta exacta se conoce.

| | ML.NET | Tribuo | scikit-learn | IX |
|---|---|---|---|---|
| Mínimos cuadrados exactos | [`Ols`](https://learn.microsoft.com/dotnet/api/microsoft.ml.mklcomponentscatalog.ols) | [`LARSTrainer`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/regression/slm/LARSTrainer.html), regresión de ángulo mínimo | [`LinearRegression`](https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.LinearRegression.html) | `ix_supervised::linear_regression::LinearRegression` |
| Por descenso de gradiente | [`OnlineGradientDescent`](https://learn.microsoft.com/dotnet/api/microsoft.ml.standardtrainerscatalog.onlinegradientdescent) | [`LinearSGDTrainer`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/regression/sgd/linear/LinearSGDTrainer.html) | [`SGDRegressor`](https://scikit-learn.org/stable/modules/sgd.html) | una función de pérdida y `ix_optimize::gradient::minimize` |
| Optimizadores | — | [`AdaGrad`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/math/optimisers/AdaGrad.html), [`Adam`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/math/optimisers/Adam.html)… | un calendario de `learning_rate` | `SGD`, `Momentum`, `Adam` |

El programa de esta lección es [`examples/l02_linear_regression.rs`](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/examples/l02_linear_regression.rs). Entrena con los 52 builds más antiguos y prueba con los 13 más recientes, la división cronológica de la lección 1.

## Mínimos cuadrados

¿Qué recta? La que tiene el menor error cuadrático medio en las filas de entrenamiento:

```text
L(w, b) = 1/n Σ (w·xᵢ + b - yᵢ)²
```

En el mínimo, las dos derivadas parciales de `L` valen cero. Resolver las dos ecuaciones da la forma cerrada, con `x̄` e `ȳ` las medias:

```text
w = Σ (xᵢ - x̄)(yᵢ - ȳ) / Σ (xᵢ - x̄)²        b = ȳ - w·x̄
```

`w` es la covarianza de páginas y segundos dividida por la varianza de las páginas ([`src/linear.rs`, líneas 5-13](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/src/linear.rs#L5-L13)):

```rust
pub fn fit_closed_form(x: &Array1<f64>, y: &Array1<f64>) -> (f64, f64) {
    let n = x.len() as f64;
    let (mx, my) = (x.sum() / n, y.sum() / n);
    let cov: f64 = x.iter().zip(y).map(|(a, b)| (a - mx) * (b - my)).sum();
    let var: f64 = x.iter().map(|a| (a - mx).powi(2)).sum();
    let w = cov / var;
    (w, my - w * mx)
}
```

Con varias características, el mismo razonamiento da la **ecuación normal**. Se añade a **X** una columna de unos para `b`; los parámetros son `θ = (XᵀX)⁻¹ Xᵀy`. Es lo que calcula [`LinearRegression::fit`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/linear_regression.rs#L57-L79), con una inversa de matriz:

```rust
let ones = Array2::ones((n, 1));
let x_aug = ndarray::concatenate(Axis(1), &[x.view(), ones.view()]).unwrap();
let xtx = x_aug.t().dot(&x_aug);
let xty = x_aug.t().dot(y);
let xtx_inv = ix_math::linalg::inverse(&xtx).expect("X^T X is singular");
let w = xtx_inv.dot(&xty);
```

```text
== least squares on the 52 training builds
hand: seconds = 0.041707 * pages + 9.708880
ix:   seconds = 0.041707 * pages + 9.708880
same to 1e-9: true
```

Unos 10 segundos de coste fijo, más 0.04 segundos por página, o 24 páginas por segundo. scikit-learn encuentra la misma recta en la comprobación cruzada. Invertir `XᵀX` está bien para unas pocas características; falla cuando dos características son copias exactas la una de la otra, en cuyo caso `XᵀX` no tiene inversa y `fit` hace panic con ese mensaje (*por verificar* con datos), y pierde precisión cuando casi lo son. Bibliotecas como scikit-learn resuelven el problema de mínimos cuadrados sin formar la inversa.

## Con los builds de prueba

```text
== 13 test builds
line:     rmse 7.952, mae 4.574, r2 -0.180
baseline: rmse 10.344, mae 7.308, r2 -0.996
  93a0ea8 274 pages: actual 23 s, predicted 21.1 s, error +1.9
  a7a6f72 274 pages: actual 21 s, predicted 21.1 s, error -0.1
  fd52d46 277 pages: actual 24 s, predicted 21.3 s, error +2.7
  bd17932 271 pages: actual 24 s, predicted 21.0 s, error +3.0
  3147e64 277 pages: actual 23 s, predicted 21.3 s, error +1.7
  e5254f6 280 pages: actual 25 s, predicted 21.4 s, error +3.6
  b96934a 283 pages: actual 18 s, predicted 21.5 s, error -3.5
  35c2e3e 283 pages: actual 20 s, predicted 21.5 s, error -1.5
  85a8c04 283 pages: actual 19 s, predicted 21.5 s, error -2.5
  b0803c9 283 pages: actual 29 s, predicted 21.5 s, error +7.5
  bcfc3fc 283 pages: actual 26 s, predicted 21.5 s, error +4.5
  849fb18 286 pages: actual 21 s, predicted 21.6 s, error -0.6
  95a3830 289 pages: actual 48 s, predicted 21.8 s, error +26.2
without the 48 s build: rmse 3.336, mae 2.769, r2 -0.234
```

La recta supera a la línea base: su error típico baja de 10 a 8 segundos, y a 3 sin el último build. Su R² sigue siendo negativo, y empeora sin ese build. Todos los builds de prueba tienen entre 271 y 289 páginas, así que la recta predice de 21 a 22 segundos para todos ellos; lo que varía de 18 a 29 segundos es algo que el número de páginas no mide. R² compara el modelo con la media del conjunto de prueba, y en ese rango estrecho la recta no tiene nada que explicar. Las métricas responden a una pregunta precisa: aquí, «¿explica el número de páginas las diferencias entre estos 13 builds?», y la respuesta es no.

El build de 48 segundos es una única ejecución de CI; no he buscado su causa (*por verificar*).

## Descenso de gradiente

La forma cerrada existe porque la pérdida es una cuadrática simple. Para la mayoría de los modelos no hay fórmula, y los parámetros se encuentran bajando la pendiente. El **gradiente** de `L` apunta cuesta arriba; cada paso mueve un poco los parámetros en la dirección opuesta, escalado por la **tasa de aprendizaje** `α`:

```text
∂L/∂w = 2/n Σ (w·xᵢ + b - yᵢ)·xᵢ        ∂L/∂b = 2/n Σ (w·xᵢ + b - yᵢ)
w ← w - α · ∂L/∂w                        b ← b - α · ∂L/∂b
```

[`src/linear.rs`, líneas 15-32](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/src/linear.rs#L15-L32):

```rust
let (mut dw, mut db) = (0.0, 0.0);
for (xi, yi) in x.iter().zip(y) {
    let error = w * xi + b - yi;
    dw += 2.0 * error * xi / n;
    db += 2.0 * error / n;
}
(w - learning_rate * dw, b - learning_rate * db)
```

Desde `w = 0` y `b = 0`, con los números de páginas tal cual, imprimiendo la pérdida tras 1, 10, 1,000 y 100,000 pasos:

```text
== gradient descent by hand, raw pages
learning rate 3e-5: step 1 loss 4.957e2 step 10 loss 3.373e4 step 1000 loss 4.538e207 step 100000 loss NaN
  -> w NaN, b NaN
learning rate 1e-5: step 1 loss 3.354e1 step 10 loss 1.565e1 step 1000 loss 1.561e1 step 100000 loss 1.235e1
  -> w 0.080177, b 1.813045
```

Con `α = 3e-5`, la pérdida crece a cada paso hasta desbordarse. Con `α = 1e-5`, tras 100,000 pasos la recta sigue lejos de `w = 0.0417, b = 9.71`. Los dos problemas tienen una sola causa: la pérdida es un valle muy empinado en una dirección y casi plano en la otra.

La curvatura de `L` es su matriz de segundas derivadas, `2 · [[mean(x²), mean(x)], [mean(x), 1]]`. Con las páginas de entrenamiento de la lección 1 (media 184.0, desviación estándar 62.5), sus valores propios son de unos 75,500 en la dirección empinada y 0.21 en la plana. Un paso se pasa de largo, y el descenso diverge, cuando `α` es mayor que 2 dividido por la curvatura más pronunciada, unos 2.6e-5: 3e-5 está por encima. Por debajo, la dirección plana se reduce en un factor `1 - α · 0.21` por paso: con `α = 1e-5`, 100,000 pasos solo eliminan una quinta parte de la distancia.

**Estandarizar** la característica vuelve redondo el valle. Con `z = (pages - μ) / σ`, `mean(z) = 0` y `mean(z²) = 1`, la curvatura es `2` en todas las direcciones, y `α = 0.1` reduce el error en un factor 0.8 por paso en ambas. La recta encontrada sobre `z` se convierte de vuelta a páginas: `w = ws / σ` y `b = bs - ws · μ / σ`.

```text
== gradient descent by hand, standardized pages, learning rate 0.1
100 steps: ws 2.605694, bs 17.384615 -> w 0.041707, b 9.708880
```

100 pasos alcanzan la forma cerrada hasta el sexto decimal. `bs` es la media de los segundos de entrenamiento, como debe ser cuando la característica tiene media 0.

## Los optimizadores de IX

`ix-optimize` separa las tres partes de un descenso: una función que minimizar, un optimizador que convierte un gradiente en un paso, y un bucle. La función implementa [`ObjectiveFunction`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-optimize/src/traits.rs#L5-L17): `evaluate` es obligatorio; `gradient` tiene una implementación por defecto que lo estima numéricamente, a partir de `(f(x + ε) - f(x - ε)) / 2ε` con `ε = 1e-7` para cada parámetro ([`calculus.rs`, líneas 7-21](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-math/src/calculus.rs#L7-L21)). El `Mse` de la lección da el gradiente exacto ([líneas 16-36](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/examples/l02_linear_regression.rs#L16-L36)); `ClosureObjective` envuelve una closure y conserva la implementación por defecto.

Los tres optimizadores, con `g` el gradiente ([`gradient.rs`, líneas 19-116](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-optimize/src/gradient.rs#L19-L116)):

| Optimizador | Paso | Idea |
|---|---|---|
| `SGD(α)` | `θ ← θ - α·g` | el descenso de arriba |
| `Momentum(α, β)` | `v ← β·v - α·g`, `θ ← θ + v` | una bola que conserva parte de su velocidad: más rápida a lo largo de un valle largo y plano |
| `Adam(α)` | `m ← β₁·m + (1-β₁)·g`, `s ← β₂·s + (1-β₂)·g²`, `θ ← θ - α·m̂ / (√ŝ + ε)` | el paso de cada parámetro dividido por el tamaño de sus gradientes recientes |

`m̂` y `ŝ` son `m` y `s` corregidos por partir de cero, e IX usa `β₁ = 0.9`, `β₂ = 0.999`. Pese a su nombre, `SGD` aquí no es estocástico: `minimize` le pasa en cada paso el gradiente sobre todas las filas. El descenso de gradiente estocástico, como `OnlineGradientDescent` de ML.NET, usa una fila o un lote pequeño por paso.

[`minimize`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-optimize/src/gradient.rs#L124-L168) se detiene cuando la longitud del gradiente cae por debajo de la tolerancia, y devuelve los mejores parámetros que ha visto:

```text
== ix_optimize::gradient::minimize, from [0, 0]
SGD(0.1), exact gradient       iterations    79, converged true , loss 5.908583, w 0.041707, b 9.708880
SGD(0.1), numerical gradient   iterations    79, converged true , loss 5.908583, w 0.041707, b 9.708880
Adam(0.1), exact gradient      iterations   868, converged true , loss 5.908583, w 0.041707, b 9.708880
closed-form loss on the training builds: 5.908583
```

El gradiente numérico no cambia nada aquí: la pérdida es una cuadrática, en la que una diferencia central es exacta salvo redondeo. `SGD` se detiene tras 79 iteraciones y el bucle a mano tras 100, porque se detienen con criterios distintos: la longitud del gradiente por debajo de 1e-6, y un paso que se mueve menos de 1e-9. Adam necesita 868: sus pasos se dividen por el tamaño reciente de los gradientes, así que no se reducen en proporción al gradiente cerca del mínimo, y el gradiente tarda más en caer por debajo de la tolerancia. Adam está pensado para problemas en los que los gradientes de distintos parámetros tienen tamaños muy diferentes; tras estandarizar, este no tiene ninguno así.

## Puntos clave

- Los mínimos cuadrados tienen una forma cerrada, `w = cov(x, y) / var(x)`, y la ecuación normal para varias características. IX la calcula con una inversa de matriz, y coincide con la versión a mano y con scikit-learn hasta 1e-9.
- El descenso de gradiente diverge cuando la tasa de aprendizaje es mayor que 2 dividido por la curvatura más pronunciada, y avanza muy despacio en las direcciones planas. Las características en escalas distintas provocan ambas cosas a la vez; estandarizar lo corrige.
- Una recta puede superar a la línea base y aun así tener un R² negativo: comprueba con qué compara la métrica el modelo.
- En IX, un modelo que entrenar es una `ObjectiveFunction`; `minimize` ejecuta el bucle con `SGD` (lote completo), `Momentum` o `Adam`, y sin un método `gradient` usa uno numérico.

## Ejercicios

Las soluciones están en [`examples/l02_exercises.rs`](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/examples/l02_exercises.rs), y su salida en `expected/l02_exercises.txt`.

1. Ajusta la recta con los 65 builds. Luego ajústala 65 veces, cada vez sin un build, e imprime los tres builds cuya eliminación más cambia la pendiente.

<details>
<summary>Solución</summary>

[Líneas 17-34](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/examples/l02_exercises.rs#L17-L34):

```rust
let (w, b) = fit_closed_form(&pages, seconds);
let mut changes: Vec<(f64, usize)> = (0..pages.len())
    .map(|i| {
        let keep: Vec<usize> = (0..pages.len()).filter(|&j| j != i).collect();
        let (wi, _) = fit_closed_form(&pick(&pages, &keep), &pick(seconds, &keep));
        ((wi - w).abs(), i)
    })
    .collect();
changes.sort_by(|a, c| c.0.total_cmp(&a.0));
```

```text
== exercise 1
all 65 builds: seconds = 0.053333 * pages + 8.0049
without 95a3830 (289 pages, 48 s): slope changes by 0.007328
without b0803c9 (283 pages, 29 s): slope changes by 0.001631
without b96934a (283 pages, 18 s): slope changes by 0.001408
```

Un build de 65 mueve la pendiente un 14 %, cuatro veces más que cualquier otro. Tiene el mayor número de páginas y el mayor error: los mínimos cuadrados elevan los errores al cuadrado, así que un punto lejos de la recta y lejos de la media es el que más tira de la recta. Es la **influencia**; la estadística la mide con la distancia de Cook, y las funciones de pérdida robustas, como la pérdida de Huber de `SGDRegressor` de scikit-learn, la reducen.

</details>

2. Con los 65 builds, estandarizados, compara `SGD` y `Momentum(0.9)` de IX desde `[0, 0]`, con tasas de aprendizaje 0.01 y 0.1. ¿Cuál necesita menos iteraciones, y por qué cambia la respuesta con la tasa de aprendizaje?

<details>
<summary>Solución</summary>

[Líneas 36-65](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/examples/l02_exercises.rs#L36-L65):

```rust
for learning_rate in [0.01, 0.1] {
    let plain = minimize(
        &objective,
        &mut SGD::new(learning_rate),
        array![0.0, 0.0],
        &criteria,
    );
    let momentum = minimize(
        &objective,
        &mut Momentum::new(learning_rate, 0.9),
        array![0.0, 0.0],
        &criteria,
    );
    // …
}
```

```text
== exercise 2
learning rate 0.01: SGD 866 iterations (loss 16.315161), Momentum(0.9) 270 iterations (loss 16.315161)
learning rate 0.1: SGD 80 iterations (loss 16.315161), Momentum(0.9) 284 iterations (loss 16.315161)
```

Momentum gana con 0.01 y pierde con 0.1. Estandarizada con sus propias filas, la pérdida tiene curvatura 2 en todas las direcciones, así que el descenso simple reduce el error en `1 - 2α` por paso: 0.98 con `α = 0.01`, 0.8 con `α = 0.1`. Con momentum, el error sigue `eₜ₊₁ = (1 + β - 2α)·eₜ - β·eₜ₋₁`; para ambas tasas de aprendizaje esta recurrencia oscila, y su amplitud se reduce en `√β ≈ 0.95` por paso. 0.95 gana a 0.98, y pierde frente a 0.8. Momentum ayuda cuando el descenso simple es lento, en valles largos y planos; en un cuenco redondo con una buena tasa de aprendizaje, solo añade sobreoscilación.

</details>

## Fuentes

- James, Witten, Hastie, Tibshirani, Taylor, *[An Introduction to Statistical Learning](https://www.statlearning.com/)*, capítulo 3
- Goodfellow, Bengio, Courville, *[Deep Learning](https://www.deeplearningbook.org/)*, capítulo 4 (curvatura y tasa de aprendizaje) y capítulo 8 (momentum, Adam)
- [scikit-learn: modelos lineales](https://scikit-learn.org/stable/modules/linear_model.html) y [descenso de gradiente estocástico](https://scikit-learn.org/stable/modules/sgd.html)
- IX en `490c395`: [`ix-supervised/src/linear_regression.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/linear_regression.rs), [`ix-optimize/src/gradient.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-optimize/src/gradient.rs), [`ix-optimize/src/traits.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-optimize/src/traits.rs)
