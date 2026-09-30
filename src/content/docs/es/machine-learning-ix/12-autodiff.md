---
title: "12. Diferenciación automática: la cinta de Wengert"
description: "Modos directo e inverso escritos a mano, y después la cinta de ix-autograd de IX comprobada frente a formas cerradas, diferencias centradas y numpy, con ocho predicciones escritas antes de la primera ejecución: las ocho se cumplieron. Sus gradientes coinciden con las formas cerradas con una diferencia menor que 10⁻¹², su backward de la FFT es correcto, y el propio ejemplo de entrenamiento de IX anuncia PASS con parámetros que sus datos no permiten identificar."
sidebar:
  order: 12
---

Las lecciones 2, 7 y 8 entrenaron modelos con gradientes derivados a mano, y la lección 7 encontró uno mal derivado: el `Dense::backward` de IX divide dos veces por el tamaño del lote (hallazgo 15). La diferenciación automática calcula el gradiente a partir del programa que calcula la pérdida, así que no queda nada que derivar. El crate fijado [`ix-autograd`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd) de IX lo hace con una cinta de Wengert. Esta lección escribe a mano los dos modos de la diferenciación automática, lee la cinta de IX y la comprueba de tres maneras: frente a formas cerradas, frente a diferencias centradas y frente a numpy.

Las ocho predicciones que pone a prueba esta lección se [escribieron en el diario](../journal/#2026-09-29--lección-12-predicha-antes-de-medir) y se commitearon antes de que existiera ninguna línea de su código. [Los resultados](../journal/#2026-09-30--lección-12-medida) vienen después. Los experimentos están en [`autodiff.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/autodiff.rs), con una prueba por predicción. [`l12_autodiff.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/examples/l12_autodiff.rs) imprime lo que miden. [`crosscheck.py`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/crosscheck/crosscheck.py) recalcula con numpy la regresión lineal, su condicionamiento y el gradiente de la FFT.

| Método | Qué da | Coste para n entradas y una salida | Error |
|---|---|---|---|
| Simbólico | Una fórmula de la derivada | Expresiones que pueden crecer mucho más que f | Exacto |
| Diferencias centradas | (f(x + εeᵢ) − f(x − εeᵢ)) / 2ε | 2n evaluaciones de f | Truncamiento y redondeo |
| Modo directo | La derivada respecto a una entrada por pasada | n pasadas | Solo redondeo |
| Modo inverso | Las derivadas respecto a todas las entradas | Una pasada hacia delante y un recorrido hacia atrás | Solo redondeo |

## 1. Modo directo y modo inverso, a mano

La diferenciación automática descompone un programa en operaciones elementales, cada una con una derivada conocida, y les aplica la regla de la cadena. La lista de esas operaciones, un valor intermedio por línea, es una lista de Wengert. [Baydin et al.](https://jmlr.org/papers/v18/17-468.html) usan f(x₁, x₂) = ln(x₁) + x₁x₂ − sin(x₂) en (2, 5) como ejemplo conductor: v₁ = ln x₁, v₂ = x₁x₂, v₃ = sin x₂, v₄ = v₁ + v₂, y f = v₄ − v₃.

**El modo directo** lleva una derivada junto a cada valor. Un número dual v + dε, con ε² = 0, lo hace con aritmética corriente: (a + bε)(c + dε) = ac + (ad + bc)ε, así que la parte en ε del resultado es la regla del producto. Se empieza con d = 1 en x₁ y d = 0 en x₂, se ejecuta f, y la parte en ε del resultado es ∂f/∂x₁. Obtener ∂f/∂x₂ requiere una segunda pasada, con las semillas intercambiadas. `Dual` en `autodiff.rs` implementa la suma, la resta, la multiplicación, `ln` y `sin`.

**El modo inverso** registra primero la lista y después la recorre hacia atrás. Mantiene un adjunto v̄ᵢ = ∂f/∂vᵢ por entrada, empieza con f̄ = 1, y cada entrada suma su adjunto, multiplicado por su derivada local, a los adjuntos de sus operandos. Un solo recorrido da la derivada respecto a cada entrada. `Tape` en `autodiff.rs` lo hace para escalares:

```text
== f(x1, x2) = ln(x1) + x1*x2 - sin(x2) at (2, 5)
  forward mode, one pass per input:  f = 11.6521, df/dx1 = 5.5000, df/dx2 = 1.7163
  reverse mode, one backward walk:   f = 11.6521, df/dx1 = 5.5000, df/dx2 = 1.7163
  entry 0: Input      value   2.0000   adjoint  5.5000
  entry 1: Input      value   5.0000   adjoint  1.7163
  entry 2: Ln(0)      value   0.6931   adjoint  1.0000
  entry 3: Mul(0, 1)  value  10.0000   adjoint  1.0000
  entry 4: Sin(1)     value  -0.9589   adjoint -1.0000
  entry 5: Add(2, 3)  value  10.6931   adjoint  1.0000
  entry 6: Sub(5, 4)  value  11.6521   adjoint  1.0000
```

La entrada 4 recibe el adjunto −1 de la resta. La entrada 1, x₂, reúne dos contribuciones: 1 × x₁ = 2 a través del producto, y −1 × cos 5 = −0,2837 a través del seno, 1,7163 en total. Son los valores de Baydin et al.: 11,652, 5,5 y 1,716.

Una pérdida de entrenamiento tiene una salida y muchas entradas, que es el caso para el que está hecho el modo inverso. Da las n derivadas parciales por un pequeño múltiplo constante del coste de f, sea cual sea n: el principio del gradiente barato de Griewank y Walther. El modo directo necesitaría n pasadas, y las diferencias centradas 2n evaluaciones.

## 2. La cinta de IX

En `ix-autograd`, un `DiffContext` contiene un `Tape`, un vector de `TapeNode`. Cada operación calcula su valor con [ndarray](https://docs.rs/ndarray/0.17.2/ndarray/struct.ArrayBase.html), apila un nodo que guarda su nombre, los identificadores de sus entradas y su valor, y devuelve el identificador del nuevo nodo. [`DiffContext::backward`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/src/ops.rs#L382-L454) recorre los índices desde la salida hasta 0 y despacha según el nombre de la operación. Ese orden de recorrido es válido porque la cinta solo crece por el final: las entradas de una operación siempre tienen índices menores que ella. Los gradientes se acumulan en un mapa de identificador a arreglo, con `+=`, así que un identificador usado dos veces reúne las dos contribuciones.

Los nodos contienen tensores enteros, así que `LinearRegressionTool::build_graph` registra diez, donde la cinta escalar de arriba necesita 265 entradas para la misma pérdida. Los datos son los del propio ejemplo de entrenamiento de IX, [`minimize_linreg_mse`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/examples/minimize_linreg_mse.rs), reconstruidos línea a línea: 20 filas y 3 variables. Las formas cerradas, con r = ŷ − y, son ∂L/∂w = (2/n)xᵀr, ∂L/∂b = (2/n)Σr y ∂L/∂x = (2/n)r wᵀ:

```text
== IX's tape for the linear regression of `minimize_linreg_mse` (20 rows, 3 features)
  10 nodes: input, input, input, input, matmul, add, sub, mul, sum, div_scalar
  ops::variance adds 6: sum, div_scalar, sub, mul, sum, div_scalar
  w = 0, b = 0: loss 0.724417, dL/dw [-0.959694, 0.656138, -0.961510], dL/db -0.032640
    largest difference from the closed forms: w < 1e-12, b < 1e-12, x < 1e-12
    hand-written scalar tape, 265 entries: loss < 1e-12, w < 1e-12, b < 1e-12
  random w, b : loss 0.312636, dL/dw [-0.439221, 0.390372, -0.475970], dL/db -0.662593
    largest difference from the closed forms: w < 1e-12, b < 1e-12, x < 1e-12
    hand-written scalar tape, 265 entries: loss < 1e-12, w < 1e-12, b < 1e-12
```

El sesgo b tiene forma [1, 1] y `add` lo difunde sobre las 20 filas. Su backward suma el gradiente recibido sobre el eje difundido, que es lo que hace `unbroadcast`, así que ∂L/∂b es una suma sobre las filas. El nodo `mul(residual, residual)` cita dos veces el mismo identificador, y el mapa suma las dos contribuciones: 2r, como en la cinta escrita a mano. Cada gradiente coincide con su forma cerrada con una diferencia menor que 10⁻¹², en w = 0 y en un punto aleatorio (P1, P2).

Las operaciones disponibles son `add`, `sub`, `mul`, `sum`, `matmul`, `div_scalar`, `mean` y `variance`, más `rfft_magnitude` tras una feature. Todavía no hay `exp`, `log`, `tanh` ni ReLU. En este commit, la cinta puede entrenar un modelo lineal con un error cuadrático, pero no una regresión logística ni una red con una no linealidad.

## 3. Lo que la cinta no comprueba

`Tensor` lleva una bandera `requires_grad`, y su documentación pide que los datos objetivo la pongan a false ([`tensor.rs` 28-32](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/src/tensor.rs#L28-L32)). Ninguna operación ni el recorrido hacia atrás la lee, así que el recorrido calcula un gradiente para cada hoja en el camino hacia la pérdida (hallazgo 29):

```text
== What the tape does not check
  y has requires_grad = false, and backward returned a gradient for it; largest difference from -(2/n)r: < 1e-12
  x, also built with requires_grad = false, gets one too: true
  add on [2, 3] and [3, 2]: Panic("called `Result::unwrap()` on an `Err` value: ShapeError/IncompatibleShape: incompatible shapes")
  sub on [2, 3] and [3, 2]: Panic("called `Result::unwrap()` on an `Err` value: ShapeError/IncompatibleShape: incompatible shapes")
  mul on [2, 3] and [3, 2]: Panic("called `Result::unwrap()` on an `Err` value: ShapeError/IncompatibleShape: incompatible shapes")
```

`LinearRegressionTool::backward` descarta a mano el gradiente de y, y su comentario dice que el recorrido lo calcula de todos modos. Quien usa directamente las operaciones los recibe todos, incluido el gradiente de 20 × 3 de x, que nadie entrena. En [PyTorch](https://docs.pytorch.org/docs/stable/notes/autograd.html), el cálculo hacia atrás nunca se realiza en los subgrafos donde ningún tensor requiere gradiente.

`add`, `sub` y `mul` devuelven un `Result`, y el comentario de `add` dice que ndarray «errors if incompatible» ([`ops.rs` 78](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/src/ops.rs#L78)). El `&a + &b` de ndarray 0.17, en cambio, entra en pánico cuando las formas no se pueden difundir, así que estas operaciones nunca devuelven `ShapeMismatch` (hallazgo 30). Un pipeline no puede capturar el error a través del `Result`. `MseLossTool` lo evita comparando las formas por su cuenta antes de construir su grafo ([`mse_loss.rs` 86-92](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/src/tools/mse_loss.rs#L86-L92)).

## 4. Comprobar un gradiente con diferencias centradas

Una diferencia centrada (f(x + εe) − f(x − εe))/2ε tiene dos errores. El truncamiento, que viene de la serie de Taylor, es de alrededor de f‴ε²/6. El redondeo es de alrededor de u|f|/ε, con u = 1,1 × 10⁻¹⁶: cada evaluación de f se equivoca en unas pocas unidades de su última cifra, y la división por ε lo amplifica. El total es mínimo cerca de ε = (3u|f|/|f‴|)^(1/3), alrededor de 10⁻⁵ cuando f y f‴ son del orden de 1 ([Nocedal y Wright](https://doi.org/10.1007/978-0-387-40065-5), sección 8.1).

Una cuadrática tiene f‴ = 0, así que solo queda el redondeo (P5). La segunda pérdida, L = Σ c_k |Y_k|, donde Y es la FFT de una señal de 64 muestras y los c_k son pesos aleatorios, tiene los dos errores (P6):

```text
== Central differences against the tape
  mean squared error at w = 0 (quadratic in w), worst of the 3 components of dL/dw:
    eps 1e-1: < 1e-12
    eps 1e-2: < 1e-12
    eps 1e-3: < 1e-12
    eps 1e-4: < 1e-12
    eps 1e-5: < 1e-12
    eps 1e-6: 6e-11
    eps 1e-7: 8e-10
    eps 1e-8: 2e-8
    eps 1e-9: 7e-8
    eps 1e-10: 6e-7
    eps 1e-11: 7e-6
    eps 1e-12: 6e-5
  L = sum c_k |FFT(x)_k|, 64 samples, worst of the 64 components of dL/dx:
    eps 1e-1: 5e-3
    eps 1e-2: 5e-5
    eps 1e-3: 5e-7
    eps 1e-4: 6e-9
    eps 1e-5: 4e-9
    eps 1e-6: 4e-8
    eps 1e-7: 5e-7
    eps 1e-8: 6e-6
    eps 1e-9: 5e-5
    eps 1e-10: 5e-4
  IX's dL/dx, first four components: [-4.429396, -6.277916, -0.459292, -5.058516]
  smallest at eps 1e-5; eps 1e-1 is 1e6 times that, eps 1e-10 1e5 times
```

En la cuadrática, cada ε de 10⁻¹ a 10⁻⁵ es exacto hasta 10⁻¹², y por debajo el error crece alrededor de diez veces por década: es solo redondeo. En la pérdida FFT, el error baja cien veces por década hasta 10⁻⁴, el ε² del truncamiento, y sube diez veces por década por debajo de 10⁻⁵, el 1/ε del redondeo. Un ε más pequeño no es más seguro. Las diferencias centradas del error cuadrático medio usan una copia de la pérdida escrita con bucles simples en un orden fijo, así que el ruido de redondeo de la tabla es el mismo en todos los sistemas.

El propio verificador de IX, [`tests/finite_diff.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/tests/finite_diff.rs), usa ε = 10⁻⁶ y comprueba cada operación bajo `sum`, que pondera todas las salidas por igual. Un peso aleatorio por salida, como los c_k aquí, comprueba además que el gradiente de cada salida llega a las entradas correctas.

## 5. El backward de la FFT

`rfft_magnitude` devuelve |Y| con Y = FFT(x). Su backward se deduce de ∂|Y_k|/∂Y_k = Y_k/|Y_k|: el gradiente recibido g se convierte en un gradiente complejo g_k Y_k/|Y_k| sobre el espectro, y la FFT es lineal, así que ese gradiente vuelve a través de una FFT inversa: ∂L/∂x = N · Re(ifft(g ⊙ Y/|Y|)). La documentación del módulo avisa de que `ix_signal::fft::rfft` devuelve las N frecuencias, no las N/2 + 1 del [`rfft`](https://numpy.org/doc/stable/reference/routines.fft.html) de numpy, así que no hace falta el reflejo hermítico ([`ops_fft.rs` 5-15](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/src/ops_fft.rs#L5-L15)). En un medio espectro, las frecuencias 1 a N/2 − 1 representan cada una a dos, k y N − k, y un backward que lo atraviese debe contarlas dos veces, salvo la componente continua y la de Nyquist: ese es el reflejo al que se refiere la documentación del módulo.

El crate mantiene esta operación tras la feature `fft-autograd`, desactivada por defecto, «until cross-checked against JAX rfft grad». Aquí se comprueba frente a diferencias centradas en 20 señales, cada una con sus propios pesos (P7):

```text
== IX's FFT-magnitude backward (feature fft-autograd)
  20 signals of 64 samples, each with its own weights, eps 1e-5: worst error over 1280 components 8e-9
```

La FFT de numpy, con la misma fórmula, da las mismas cuatro primeras componentes, −4,429396, −6,277916, −0,459292 y −5,058516, y coincide con las diferencias centradas de numpy con una diferencia menor que 10⁻⁶. Es una comprobación frente a diferencias finitas y numpy, no la comparación con JAX que pide el crate. Una frecuencia cuya magnitud es menor que 10⁻¹⁵ recibe un gradiente nulo, una elección válida donde |·| tiene un pico; esta lección no probó ninguna señal con una frecuencia así.

## 6. El propio ejemplo de IX, reproducido

`minimize_linreg_mse` construye 20 filas de 3 variables a partir de un hash del índice, fija y = x · [0,5; −0,3; 0,8] + 0,1 + ruido, y entrena w y b con [Adam](https://arxiv.org/abs/1412.6980) durante 200 pasos. `ix_example_adam` en `autodiff.rs` lo reproduce línea a línea. El propio ejemplo, compilado desde el commit fijado en un crate de trabajo, imprime los mismos números: pérdida 0,010101 en el paso 30, por debajo de 0,01 por primera vez en el paso 31, w final [0,64994; −0,30000; 0,65006], b 0,09832, y «R7 Day 3 go/no-go: PASS».

```text
== IX's `minimize_linreg_mse`, replayed
  k in the noise -0.01 + k*0.02/32767, rows 0 to 19: 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 2 2 2
  x[i, 2] - x[i, 0] over the 20 rows: min 0.055422, max 0.055483
  least squares: w [0.499818, -0.300000, 0.800182], b 0.089990, w0 + w2 = 1.300000, mean squared error < 1e-12
  Adam step   1: loss 7.24e-1
  Adam step  10: loss 4.97e-2
  Adam step  20: loss 4.70e-2
  Adam step  30: loss 1.01e-2
  Adam step  40: loss 4.38e-3
  Adam step  50: loss 1.26e-3
  Adam step  60: loss 9.15e-4
  Adam step  70: loss 4.99e-5
  Adam step  80: loss 1.38e-4
  Adam step  90: loss 1.07e-5
  Adam step 100: loss 9.91e-6
  Adam step 110: loss 5.94e-6
  Adam step 120: loss 2.67e-7
  Adam step 130: loss 4.22e-7
  Adam step 140: loss 2.88e-7
  Adam step 150: loss 3.74e-8
  Adam step 160: loss 5.52e-9
  Adam step 170: loss 9.65e-9
  Adam step 180: loss 4.55e-9
  Adam step 190: loss 6.52e-10
  Adam step 200: loss 2.35e-11
  after 200 steps: w [0.649940, -0.300002, 0.650065], b 0.098315, w0 + w2 = 1.300005, loss 2.35e-11
  loss below 0.01 first at step 31; the example prints 7500 / 31 = 242x as its speedup over a genetic algorithm
```

**El ruido es una constante.** El ejemplo añade un «tiny deterministic noise» para que la pérdida final no sea cero. Para las filas 0 a 19, `(i·7919 + 31) >> 16` vale 0, 1 o 2, así que el ruido es −0,01 más como mucho 1,2 × 10⁻⁶. El término independiente lo absorbe: los mínimos cuadrados dan b = 0,089990 y un error cuadrático medio inferior a 10⁻¹², y Adam llega a 2,35 × 10⁻¹¹ (P8, hallazgo 32).

**Dos de las tres variables son una sola.** Avanzar dos índices hace avanzar el hash en 2 × 1103515245, que es 33 676,6 × 2¹⁶. Tras `>> 16` y `& 0x7fff`, el valor avanza +908 o +909, y al dividir por 32 767 y duplicar queda en 0,05542 o 0,05548. Ninguna de las 20 filas da la vuelta, así que la columna 2 es la columna 0 más 0,0554, con un margen de un paso de 6 × 10⁻⁵. numpy sitúa el menor valor singular de [x 1] en 8,9 × 10⁻⁵, un número de condición de 51 251. Los datos determinan w₀ + w₂ = 1,3 y b, y el reparto entre w₀ y w₂ solo a través de esa pequeña oscilación.

- **Los mínimos cuadrados** aprovechan esa oscilación y caen cerca de la verdad, en [0,499818; −0,300000; 0,800182].
- **Adam** empieza en cero, donde las dos columnas dan a w₀ y w₂ casi el mismo gradiente en cada paso. Adam ajusta el paso de cada coordenada según el historial de su propio gradiente, así que las dos dan casi los mismos pasos y terminan en 0,650 cada una.

Las dos llegan a una pérdida cercana a 10⁻¹¹. El ejemplo imprime el w final junto al w verdadero, a 0,21 de distancia, y después «PASS»: su criterio es solo la pérdida (hallazgo 31). La aceleración que anuncia es 7500 dividido por el número de pasos, donde 7500 es el punto medio de las «~5000-10000 fitness evaluations» que un algoritmo genético necesitaría «typically». El ejemplo nunca ejecuta uno (hallazgo 33).

## 7. Las predicciones, puntuadas

| | Predicción, escrita antes de la primera ejecución | Medida | Veredicto |
|---|---|---|---|
| P1 | La regresión lineal registra 10 nodos, en un orden dado; `variance` añade 6 | 10 y 6, en ese orden | Confirmada |
| P2 | Los gradientes igualan las formas cerradas con un margen de 10⁻¹², en w = 0 y en un punto aleatorio; la cinta escrita a mano coincide | Menos de 10⁻¹² para w, b y x, en ambos puntos | Confirmada |
| P3 | y, con `requires_grad` a false, recibe aun así un gradiente, igual a −(2/n)r | Sí, con una diferencia menor que 10⁻¹² | Confirmada |
| P4 | `add`, `sub` y `mul` entran en pánico con [2, 3] y [3, 2] | Las tres entran en pánico | Confirmada |
| P5 | Cuadrática: error de como mucho 10⁻¹² con ε = 0,1, de al menos 10⁻⁹ con ε = 10⁻¹⁰ | Menos de 10⁻¹²; 6 × 10⁻⁷ | Confirmada |
| P6 | Pérdida FFT: el mejor ε está en [10⁻⁶; 10⁻³], y ε = 10⁻¹ y 10⁻¹⁰ son cada uno al menos 100 veces peores | 10⁻⁵; 10⁶ y 10⁵ veces peores | Confirmada |
| P7 | Backward de la FFT a menos de 10⁻⁶ de las diferencias centradas con ε = 10⁻⁵, en 20 señales | 8 × 10⁻⁹ | Confirmada |
| P8 | Mínimos cuadrados con los datos del ejemplo: b en [0,0899; 0,0901], error cuadrático medio inferior a 10⁻¹¹ | 0,089990; inferior a 10⁻¹² | Confirmada |

Las ocho predicciones se cumplieron en la primera ejecución, y ninguna se ajustó después. P3, P4 y P8 se escribieron para detectar una diferencia entre la documentación de IX y su código, encontrada leyéndolo primero, y las tres la encontraron. Las variables colineales, el resultado que más importa aquí, no estaban predichas: P8 explicaba el término independiente y no vio los pesos. El diario las registra como exploratorias.

## Qué usar en nuestros repositorios

- **El modo inverso** para una pérdida escalar sobre muchos parámetros. **El modo directo**, con números duales, para pocas entradas, o para comprobar una derivada direccional.
- **`ix-autograd` de IX:** sus gradientes son exactos para las operaciones que tiene, que cubren modelos lineales, errores cuadráticos, varianzas y magnitudes de FFT. No confíes en `requires_grad`. Comprueba las formas antes de llamar a `add`, `sub` o `mul`, porque un desacuerdo provoca un pánico.
- **Un backward nuevo:** compruébalo frente a diferencias centradas con ε cercano a 10⁻⁵, un peso aleatorio por salida, en un punto alejado de los picos.
- **Antes de leer parámetros ajustados,** comprueba que los datos los determinan: el número de condición de la matriz de diseño, o dos optimizadores que deberían coincidir. Una pérdida baja no dice nada de qué mínimo se encontró.

## Ejercicios

1. Ejecuta a mano el modo directo sobre g(x₁, x₂) = x₁x₂ + sin(x₁) en (0, 3): escribe el valor y la parte en ε de cada intermedio, en las dos pasadas.
2. El recorrido hacia atrás de IX visita los nodos por índice decreciente. ¿Por qué ningún nodo se visita antes que un nodo que lo usa? ¿Qué fallaría si una operación pudiera sobrescribir un nodo existente, como hace una actualización en el sitio?
3. Con ε = 10⁻¹⁰, el error de la cuadrática es 6 × 10⁻⁷. Estímalo a partir del redondeo solo: la pérdida vale 0,724, y cada evaluación se equivoca en alrededor de una unidad de su última cifra.
4. Escribe la regla backward de una operación `exp` para la cinta de IX: ¿qué necesita de la pasada hacia delante y qué devuelve?

<details>
<summary>Soluciones</summary>

1. Primera pasada, semilla en x₁: x₁ = 0 + 1ε, x₂ = 3 + 0ε, x₁x₂ = 0 + 3ε, sin x₁ = 0 + cos(0)ε = 0 + 1ε, g = 0 + 4ε, así que ∂g/∂x₁ = x₂ + cos x₁ = 4. Segunda pasada, semilla en x₂: x₁x₂ = 0 + 0ε, porque la parte en ε es x₁ × 1 = 0, y sin x₁ = 0 + 0ε, así que ∂g/∂x₂ = x₁ = 0.
2. La cinta solo crece por el final: una operación se apila cuando sus entradas ya existen, así que cada nodo que usa un nodo dado tiene un índice mayor, y un recorrido por índice decreciente los alcanza a todos antes. Una operación en el sitio daría a un nodo un valor nuevo después de que otros nodos hubieran leído el antiguo. Sus reglas backward leerían entonces el valor equivocado, y el orden de los índices ya no coincidiría con el orden de uso.
3. La diferencia de dos evaluaciones de 0,724 se equivoca en alrededor de 2 × 0,724 × 1,1 × 10⁻¹⁶ ≈ 1,6 × 10⁻¹⁶. Dividido por 2ε = 2 × 10⁻¹⁰, da alrededor de 8 × 10⁻⁷, cerca de los 6 × 10⁻⁷ medidos.
4. La derivada de eᵃ es eᵃ, es decir, la propia salida de la operación, así que el valor del nodo es todo lo que necesita el backward. Devuelve g ⊙ valor para su única entrada, sin `unbroadcast`, porque la operación conserva la forma.

</details>

## Fuentes

- IX en el commit fijado `490c395`: [`ops.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/src/ops.rs), [`tape.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/src/tape.rs), [`tensor.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/src/tensor.rs), [`ops_fft.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/src/ops_fft.rs), [`linear_regression.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/src/tools/linear_regression.rs), [`minimize_linreg_mse.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/examples/minimize_linreg_mse.rs) y [`finite_diff.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/tests/finite_diff.rs).
- R. E. Wengert, [«A simple automatic derivative evaluation program»](https://doi.org/10.1145/355586.364791), *Communications of the ACM* 7(8), 1964.
- A. G. Baydin, B. A. Pearlmutter, A. A. Radul y J. M. Siskind, [«Automatic differentiation in machine learning: a survey»](https://jmlr.org/papers/v18/17-468.html), *Journal of Machine Learning Research* 18, 2018: el ejemplo conductor, los modos directo e inverso.
- A. Griewank y A. Walther, [*Evaluating Derivatives*](https://doi.org/10.1137/1.9780898717761), 2.ª edición, SIAM, 2008: la cinta y el principio del gradiente barato.
- J. Nocedal y S. J. Wright, [*Numerical Optimization*](https://doi.org/10.1007/978-0-387-40065-5), 2.ª edición, Springer, 2006, sección 8.1: el error de las diferencias finitas.
- D. P. Kingma y J. Ba, [«Adam: a method for stochastic optimization»](https://arxiv.org/abs/1412.6980), ICLR 2015.
