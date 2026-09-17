---
title: "7. Redes neuronales, y las diferencias finitas como juez"
description: "Una capa afín y la retropropagación escritas a mano y comprobadas contra diferencias centradas, luego ix_nn — el gradiente que Dense aplica de verdad, que es el verdadero dividido por el tamaño del lote, la pérdida cuyo gradiente se desvía por el número de columnas de salida, pesos sorteados sin semilla, y un Sequential de capas Dense que sigue siendo una sola aplicación afín porque el crate no tiene ninguna capa de activación."
sidebar:
  order: 7
---

Todos los modelos hasta ahora tenían una forma elegida de antemano: una recta, una frontera, un árbol. Una **red neuronal** casi no tiene forma. Es una pila de dos tipos de paso — una aplicación afín `y = xW + b`, y una función no lineal fija aplicada a cada número — y lo que puede representar depende solo de cuántos apiles.

La parte que merece aprenderse a mano no es el apilado. Es la **retropropagación**: la regla de la cadena aplicada hacia atrás a través de la pila, que convierte una pérdida en un gradiente para cada peso. Es también la parte fácil de equivocar sutilmente y difícil de notar, y por eso esta lección se apoya en la única herramienta que zanja esas discusiones — las **diferencias finitas**, que no saben nada de la regla de la cadena y solo pueden medir.

| | ML.NET | Tribuo | PyTorch | IX |
|---|---|---|---|---|
| Una capa | — | [`Layer`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/interop/tensorflow/package-summary.html) vía TensorFlow | `nn.Linear` | `ix_nn::layer::Dense` |
| Una pila | — | — | `nn.Sequential` | `ix_nn::network::Sequential` |
| Activaciones | — | — | `nn.ReLU`, `nn.Sigmoid`… | ninguna que implemente `Layer` |
| Pérdidas | — | — | `nn.MSELoss` | `mse_loss`, `binary_cross_entropy` |
| Gradientes automáticos | — | — | autograd | `ix-autograd`, un crate aparte con su propia cinta |

El programa es [`examples/l07_networks.rs`](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/examples/l07_networks.rs), sobre las 65 compilaciones de la lección 2 con ambas columnas estandarizadas.

## Una capa, y sus tres gradientes

Para `y = xW + b`, la regla de la cadena da tres cosas a la vez. Escribe `g = dL/dy`, el gradiente que la capa recibe de arriba:

```text
dL/dW = xᵀ g          dL/db = Σ rows of g          dL/dx = g Wᵀ
```

Los dos primeros actualizan esta capa; el tercero es el mensaje que se pasa a la capa de abajo. La versión a mano devuelve los tres y no aplica ninguno ([`src/net.rs`, líneas 40-55](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/src/net.rs#L40-L55)):

```rust
pub fn backward(&self, x: &Array2<f64>, grad_output: &Array2<f64>) -> LinearGrads {
    LinearGrads {
        weights: x.t().dot(grad_output),
        bias: grad_output.sum_axis(Axis(0)),
        input: grad_output.dot(&self.weights.t()),
    }
}
```

No aparece ninguna división por el tamaño del lote, y no debería: el promediado que quiera la pérdida ya está dentro de `g`. Si la pérdida es una media sobre `n` filas, su propio gradiente lleva el `1/n`.

El juez está de acuerdo:

```text
== the hand layer, judged by finite differences
  analytic -0.534895701, numeric -0.534895701, gap 4.35e-11
```

El valor numérico viene de la diferencia centrada `(f(w + h) - f(w - h)) / 2h` con `h = 1e-6`, cuyo error es de orden `h²`, unos `1e-12`, más el redondeo. Una brecha de `4e-11` es un aprobado. Cualquier error real en `backward` — una transpuesta que falta, un factor olvidado — aparece como una brecha de orden 1, no de orden `1e-11`.

## El gradiente que `Dense` aplica de verdad

`ix_nn::layer::Dense` no devuelve sus gradientes; `backward` actualiza los pesos él mismo y solo devuelve el mensaje para la capa de abajo ([`layer.rs`, líneas 40-52](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/layer.rs#L40-L52)):

```rust
let grad_weights = input.t().dot(grad_output) / n;
let grad_bias = grad_output.mean_axis(ndarray::Axis(0)).unwrap();
let grad_input = grad_output.dot(&self.weights.t());
self.weights = &self.weights - &(learning_rate * &grad_weights);
```

Así que la pregunta «¿qué resta `Dense`?» puede responderse por experimento en vez de por lectura: fijar los pesos a mano, llamar a `backward` con una tasa de aprendizaje de 1, y ver cuánto se movieron. Al lado, medir el gradiente de `ix_nn::loss::mse_loss` con diferencias centradas.

```text
== ix_nn::layer::Dense, one output column
  gradient of mse_loss, measured: -0.534895701
  what backward subtracts:        -0.008229165
  ratio: 65.0000, and the batch has 65 rows
```

Exactamente 65: el número de filas. `grad_output` ya lleva el `1/n` que puso ahí `mse_gradient`, y `backward` divide por `n` una segunda vez. La dirección es correcta, así que el entrenamiento sigue funcionando — pero la tasa de aprendizaje que pasas no es la que obtienes. Sobre estas 65 filas, `learning_rate = 0.1` se comporta como 0,0015; sobre un lote de 10 000 se comportaría como `1e-5`, y una red que entrena bien con un conjunto pequeño parecería congelada con uno grande. Nada más cambia, porque cada `Dense` divide por el mismo `n`, de modo que las capas se mantienen en proporción entre sí.

## Una pérdida y un gradiente que no encajan

`mse_loss` promedia sobre cada celda de la matriz, filas *y* columnas. `mse_gradient` divide solo por las filas ([`loss.rs`, líneas 6-16](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/loss.rs#L6-L16)):

```rust
pub fn mse_loss(predicted: &Array2<f64>, target: &Array2<f64>) -> f64 {
    let diff = predicted - target;
    diff.mapv(|v| v * v).mean().unwrap()
}

pub fn mse_gradient(predicted: &Array2<f64>, target: &Array2<f64>) -> Array2<f64> {
    let n = predicted.nrows() as f64;
    2.0 * (predicted - target) / n
}
```

Con una sola columna de salida ambas coinciden. Con `m` columnas, `mse_gradient` es `m` veces el gradiente verdadero de `mse_loss`, y los dos efectos se componen:

```text
== the same layer with two output columns
  measured gradient [-0.267448, -1.234896]
  backward subtracts [-0.008229, -0.037997]
  ratios [32.5000, 32.5000]
```

32,5 es `65 / 2`: dividido por 65 filas por `Dense`, multiplicado por 2 columnas por `mse_gradient`. El ejercicio lleva la razón hasta cuatro columnas y obtiene 1, 2, 3, 4 exactamente. Toda red de IX con más de una salida se entrena, por tanto, con una tasa de aprendizaje escalada por el número de salidas, que es el tipo de cosa que convierte «ajustamos la tasa de aprendizaje» en folclore.

## Pesos que nadie puede reproducir

`Dense::new` sortea sus pesos de una distribución normal sin una semilla a la vista ([`layer.rs`, línea 27](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/layer.rs#L27)):

```rust
weights: Array2::random((input_size, output_size), Normal::new(0.0, std).unwrap()),
```

`ndarray_rand::RandomExt::random` extrae del generador del hilo, así que dos capas construidas en la misma ejecución ya difieren, y dos ejecuciones del mismo programa también:

```text
== Dense::new(3, 2) twice in the same run
  the two weight matrices are equal: false
  all zero biases: true, weights are public, so a course can overwrite them
```

Todos los demás algoritmos aleatorios de IX toman una semilla — `KMeans::with_seed`, `RandomForest::with_seed`, `Dropout::new(p, seed)`, `transformer::FeedForward::new(d_model, d_ff, seed)`. `Dense` es la excepción, y la consecuencia es que ningún resultado de `Sequential` puede reproducirse ni someterse a pruebas de regresión. La salida es que `weights` y `bias` son campos públicos: construir la capa y luego sobrescribirlos, que es lo que hace esta lección en todas partes.

## Qué puede representar una pila de capas `Dense`

Dos aplicaciones afines seguidas son una sola aplicación afín: `(xA + a)B + b = x(AB) + (aB + b)`. Una red solo pasa a ser más que una recta cuando algo no lineal se sitúa entre sus capas.

`ix-nn` tiene un trait `Layer` con `forward` y `backward`, y exactamente un tipo lo implementa: `Dense`. No hay capa `ReLU`, ni capa `Sigmoid`, nada que `Sequential::push` pudiera aceptar entre dos aplicaciones afines. (El crate sí tiene un GELU — `transformer::gelu` — pero vive dentro de `FeedForward`, trabaja sobre `Array3` y no es un `Layer`.)

El **o exclusivo** es el problema más pequeño que muestra lo que eso cuesta. Cuatro puntos, y ninguna recta separa las dos clases:

```text
== exclusive or
  hand, two affine layers with a sigmoid between them: loss 0.35722182 -> 0.00000000
  predictions [0.0000, 1.0000, 1.0000, 0.0000]
  ix_nn, two Dense layers and nothing between them: loss 0.34500000 -> 0.25000000
  predictions [0.5000, 0.5000, 0.5000, 0.5000]
  f(0,0) + f(1,1) - f(0,1) - f(1,0) = 0.00e0: the stack is one affine map
```

La red a mano — mismo tamaño, misma tasa de aprendizaje, las mismas 50 000 épocas, una sigmoide entre las capas — lo resuelve exactamente. La pila de IX converge a 0,25 y predice 0,5 en todas partes: 0,25 es la varianza de los cuatro objetivos, lo mejor que puede hacer una constante, y una constante es lo mejor que puede hacer aquí una aplicación afín.

La última línea es la demostración, no el síntoma. Para cualquier `f` afín, `f(0,0) + f(1,1) = f(0,1) + f(1,0)`, porque ambos lados son `2f` evaluada en el mismo centro. La pila entrenada lo satisface hasta el último bit, tras 50 000 épocas de entrenamiento, a cualquier profundidad. No está poco entrenada; no puede representar la función.

Nada de esto hace que `ix-nn` esté mal — la atención, la normalización de capa, RoPE, ALiBi y los bloques transformer del mismo crate son donde está su trabajo de verdad, y esos sí tienen sus no linealidades. Pero `Sequential` más `Dense` es la parte que parece una API de red neuronal para principiantes, y es la parte que solo puede ajustar rectas.

## Puntos clave

- La pasada hacia atrás de una capa afín da tres gradientes, `xᵀ g`, la suma de las filas de `g` y `g Wᵀ`. Las diferencias centradas los comprueban hasta unos `1e-11`, y cualquier error real aparece como una diferencia del orden de 1.
- `Dense::backward` divide una segunda vez por el tamaño del lote, así que la tasa de aprendizaje que pasas se encoge con el número de filas.
- `mse_loss` promedia sobre todas las celdas pero `mse_gradient` divide solo por las filas: con `m` columnas de salida, el gradiente es `m` veces el verdadero.
- `Dense::new` sortea sus pesos sin semilla; sobrescribe los campos públicos `weights` y `bias` para que un resultado sea reproducible.
- Dos aplicaciones afines seguidas son una sola. Sin capa de activación, un `Sequential` de capas `Dense` de IX predice 0.5 en todas partes con el o exclusivo, mientras que una sigmoide entre las capas lo resuelve.

## Ejercicios

1. Elige una tasa de aprendizaje que haga que un paso de `Dense` aterrice exactamente donde aterriza un paso de la capa a mano.
2. Mide `mse_gradient` contra el gradiente verdadero de `mse_loss` para una a cuatro columnas de salida.
3. ¿Cómo de ancha tiene que ser la capa oculta antes de que la red a mano resuelva el o exclusivo?

<details>
<summary>Soluciones</summary>

Están en [`examples/l07_exercises.rs`](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/examples/l07_exercises.rs).

**1.** Multiplica por el número de filas, el factor medido arriba:

```text
== matching one step of the hand layer with one step of Dense
  hand weight after one step at rate 0.5      0.667447851
  Dense weight after one step at rate 0.5 x 65  0.667447851
  gap 0.00e0
```

No aproximadamente — bit a bit, porque la única diferencia entre los dos caminos de código es una multiplicación. El punto de llegada merece una segunda mirada: 0,667447851 es la pendiente de mínimos cuadrados en forma cerrada de la lección 2. Con ambas columnas estandarizadas la pérdida es `w² - 2rw + 1`, cuyo gradiente es `2w - 2r`, así que un paso de tasa 0,5 desde cualquier punto de partida aterriza exactamente en `r`. Un paso, sin iteración.

**2.** La razón es el número de columnas de salida:

```text
== ix_nn::loss::mse_gradient divided by the true gradient of mse_loss
  1 column(s): ratio [1.0000], and mse_loss = 0.626042
  2 column(s): ratio [2.0000], and mse_loss = 1.859063
  3 column(s): ratio [3.0000], and mse_loss = 3.758750
  4 column(s): ratio [4.0000], and mse_loss = 6.325104
```

**3.** Dos unidades sigmoides bastan, y una no:

```text
== width of the hidden layer against what it can learn (exclusive or)
  hidden 1: final loss 0.166788, corners right 3 of 4
  hidden 2: final loss 0.000000, corners right 4 of 4
  hidden 3: final loss 0.000000, corners right 4 of 4
  hidden 4: final loss 0.000000, corners right 4 of 4
```

Una unidad sigmoide traza una frontera, y el o exclusivo necesita dos; acierta tres esquinas y se estabiliza en 0,167, mejor que el 0,25 de una constante pero no una solución. Dos unidades trazan dos fronteras, y la capa de salida las combina. Es el ejemplo más pequeño del resultado general — una sola capa oculta de anchura suficiente puede aproximar cualquier función continua — y de su mitad inútil: el teorema dice que existe una anchura, no cuál.

</details>

## Fuentes

- Rumelhart, Hinton y Williams, *[Learning representations by back-propagating errors](https://www.nature.com/articles/323533a0)*, 1986
- Goodfellow, Bengio, Courville, *[Deep Learning](https://www.deeplearningbook.org/)*, capítulo 6, incluida la comprobación del gradiente por diferencias finitas
- Nielsen, *[Neural Networks and Deep Learning](http://neuralnetworksanddeeplearning.com/chap2.html)*, capítulo 2, para la retropropagación paso a paso
- [PyTorch: `torch.autograd.gradcheck`](https://docs.pytorch.org/docs/stable/generated/torch.autograd.gradcheck.html), la misma prueba como función de biblioteca
- IX en `490c395`: [`ix-nn/src/layer.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/layer.rs), [`ix-nn/src/network.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/network.rs), [`ix-nn/src/loss.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/loss.rs), [`ix-nn/src/transformer.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/transformer.rs)
