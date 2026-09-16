---
title: "8. Optimización: descenso, momento, Adam y búsquedas sin gradiente"
description: "Tres reglas de actualización por el valle de Rosenbrock, escritas a mano e igualadas paso a paso por ix_optimize; qué cuesta en evaluaciones un gradiente que nadie escribió; por qué minimize devuelve una respuesta finita para una ejecución que divergió a NaN; y el recocido simulado y el enjambre de partículas sobre la misma función."
sidebar:
  order: 8
---

La lección 2 ajustaba una recta por descenso de gradiente y descubría que un paso demasiado grande diverge. La lección 7 descubría que el tamaño del paso no siempre es el número que pasaste. Esta lección mira la regla de actualización en sí, sobre una función elegida para hacer visibles las diferencias.

La **función de Rosenbrock**, `(1 - x)² + 100(y - x²)²`, tiene su mínimo en `(1, 1)`, donde vale 0. Alrededor de ese mínimo discurre un valle largo, curvo, casi plano, de paredes empinadas. El descenso simple rebota entre las paredes y se arrastra por el fondo; es la forma habitual de ver qué compran el momento y los tamaños de paso por coordenada.

| | ML.NET | Tribuo | PyTorch | IX |
|---|---|---|---|---|
| Descenso simple | `OnlineGradientDescent` | [`SGD`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/math/optimisers/SGD.html) | `optim.SGD` | `ix_optimize::gradient::SGD` |
| Momento | — | `SGD.getLinearDecaySGD` con momento | `optim.SGD(momentum=…)` | `ix_optimize::gradient::Momentum` |
| Adam | — | [`Adam`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/math/optimisers/Adam.html) | `optim.Adam` | `ix_optimize::gradient::Adam` |
| Sin gradiente | — | — | — | `annealing::SimulatedAnnealing`, `pso::ParticleSwarm` |

El programa es [`examples/l08_optimization.rs`](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/examples/l08_optimization.rs), partiendo de `(-1.2, 1.0)`, el punto que usa el artículo de Rosenbrock.

## Tres reglas

El **descenso simple** resta el gradiente: `p ← p - α g`. Tiene un problema en un valle — el gradiente apunta a través del valle mucho más fuerte que a lo largo de él, así que la mayor parte del paso se desperdicia yendo y viniendo.

El **momento** mantiene una velocidad corriente, `v ← βv + αg`, y resta esa. Los pasos que siguen apuntando en la misma dirección se acumulan; los que alternan se cancelan. En un valle es exactamente el instinto correcto.

**Adam** mantiene dos medias corrientes: la media del gradiente y la media de su cuadrado. Divide una por la raíz de la otra, lo que da a cada coordenada su propio tamaño de paso — grande donde el gradiente ha sido pequeño y constante, pequeño donde ha sido grande y ruidoso. Ambas medias parten de cero, así que los primeros pasos serían demasiado pequeños; dividir por `1 - βᵗ` lo corrige ([`src/optimize.rs`, líneas 101-125](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/src/optimize.rs#L101-L125)):

```rust
let mean_hat = &mean / (1.0 - self.beta1.powf(t));
let square_hat = &square / (1.0 - self.beta2.powf(t));
let next = params - &(self.learning_rate * &mean_hat / &(square_hat.mapv(f64::sqrt) + self.epsilon));
```

```text
== by hand, 5000 steps at most
  SGD        5000 steps: last [0.9387, 0.8810] f 0.003761, best f 0.003761
  Momentum   4129 steps: last [1.0000, 1.0000] f 0.000000, best f 0.000000
  Adam       2822 steps: last [1.0000, 1.0000] f 0.000000, best f 0.000000

== ix_optimize::gradient::minimize, the same 5000 steps
  SGD        5000 steps: best [0.9387, 0.8810] f 0.003761, converged false
  Momentum   4129 steps: best [1.0000, 1.0000] f 0.000000, converged true
  Adam       2822 steps: best [1.0000, 1.0000] f 0.000000, converged true
```

El descenso simple agota sus 5000 pasos sin llegar al mínimo. El momento, con la misma tasa de aprendizaje, llega en 4129. Adam llega en 2822 con una tasa cincuenta veces mayor, que es la razón práctica por la que es el valor por defecto casi en todas partes: es mucho menos sensible al número que elijas.

La versión a mano e `ix_optimize` coinciden exactamente — mismos recuentos de pasos, mismos puntos finales y el mismo primer paso desde el mismo gradiente:

```text
== the first Adam step from the same gradient
  gradient [-215.6000, -88.0000]
  hand [-1.15000000, 1.05000000]
  ix   [-1.15000000, 1.05000000]
```

Ese primer paso merece leerse. El gradiente es `[-215.6, -88]`, tremendamente distinto en las dos coordenadas, y Adam mueve ambas exactamente 0,05 — la tasa de aprendizaje. En el primer paso la corrección de sesgo hace que `mean_hat` sea igual al gradiente y `square_hat` igual al gradiente al cuadrado, así que la razón es el *signo* del gradiente y nada más. Adam empieza ignorando por completo el tamaño del gradiente.

## Un gradiente que nadie escribió

`ObjectiveFunction::gradient` tiene una implementación por defecto: si no proporcionas una, se mide con diferencias centradas ([`traits.rs`, líneas 10-13](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-optimize/src/traits.rs#L10-L13)):

```rust
fn gradient(&self, x: &Array1<f64>) -> Array1<f64> {
    ix_math::calculus::numerical_gradient(&|p: &Array1<f64>| self.evaluate(p), x, 1e-7)
}
```

`ClosureObjective`, el envoltorio de comodidad, nunca lo redefine. Así que envolver una closure cuesta dos evaluaciones extra del objetivo por coordenada y por paso — y compra un gradiente exacto hasta unos ocho dígitos:

```text
== the gradient at the start, written and measured
  written  [-215.600000000, -88.000000000]
  measured [-215.600000093, -87.999999998]
  largest gap 9.30e-8, and two extra evaluations of f per coordinate per step
  Adam on ClosureObjective: best f 1.061e-16 against 1.061e-16 with the written gradient
```

Las dos ejecuciones aterrizan en el mismo valor hasta el último dígito impreso. Esa es la conclusión honesta aquí: para un objetivo suave en dos dimensiones, el gradiente medido es suficientemente bueno, y el coste está en evaluaciones, no en precisión. El ejercicio las cuenta — 1001 frente a 201 para 200 pasos — y la razón crece con el número de parámetros, que es por lo que nadie entrena una red neuronal así.

## Una respuesta finita para una ejecución que divergió

`minimize` recuerda el mejor punto por el que ha pasado y devuelve ese, no donde terminó ([`gradient.rs`, líneas 124-165](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-optimize/src/gradient.rs#L124-L165)). Normalmente es una gentileza. Cuando la ejecución diverge es una trampa:

```text
== a step size that diverges
  ix SGD lr 0.01: best f 24.200000 after 5000 steps, converged false
  the same run by hand ends at f NaN — the best point hides the divergence
```

24,200000 es `f(-1.2, 1.0)` — el punto de partida. Con una tasa de aprendizaje de 0,01 el primerísimo paso se pasa, cada uno posterior se pasa más, los valores se disparan al infinito y luego a NaN, y como ningún valor fue nunca menor que el primero, `best_params` sigue siendo el punto que pasó el llamante. El resultado parece una respuesta corriente: un valor finito, un punto finito, 5000 iteraciones.

El único campo que protesta es `converged: false` — y el descenso simple devuelve `converged: false` también para una ejecución que terminó perfectamente bien en 0,003761. Así que `converged` no separa ambos casos, y `best_value` tampoco. Quien quiera saber si una optimización funcionó tiene que comparar el objetivo en el punto devuelto con el objetivo en el inicio, y rechazar un resultado que no haya mejorado.

## Dos búsquedas que nunca piden un gradiente

Algunos objetivos no tienen gradiente — una configuración discreta, una simulación, una puntuación de una caja negra. IX incluye dos de las respuestas clásicas.

El **recocido simulado** propone un vecino aleatorio y siempre lo acepta si es mejor; si es peor lo acepta de todos modos con probabilidad `exp(-Δ/T)`, donde la temperatura `T` cae con el tiempo. Caliente, deambula libremente y escapa de mínimos locales; frío, solo baja.

El **enjambre de partículas** hace volar una población de puntos, cada uno atraído hacia el mejor punto que ha visto personalmente y hacia el mejor punto que ha visto cualquiera.

```text
== without a gradient
  simulated annealing, seed 42: best [0.9934, 0.9881] f 0.000193 after 3216 iterations
  particle swarm, 40 particles, seed 42: best [1.0000, 1.0000] f 0.000000
```

El recocido se detiene en la iteración 3216, cuando el programa exponencial lleva la temperatura por debajo de `min_temp`, y obtiene cuatro dígitos de la respuesta. El enjambre, con 40 partículas en 200 iteraciones — 8000 evaluaciones — aterriza en el mínimo. Ambos se comportan dignamente en un problema donde el gradiente escrito necesitó 2822 pasos; ambos serían mala elección *precisamente porque* el gradiente existe.

## De vuelta a la recta

Las mismas tres reglas sobre la pérdida de la lección 2, estandarizada, donde la respuesta se conoce:

```text
== the build-time line, standardized: closed form slope 0.667448, intercept 0
  SGD        106 steps: slope 0.667448, intercept -0.000000, loss 0.554513
  Momentum   366 steps: slope 0.667448, intercept -0.000000, loss 0.554513
  Adam       384 steps: slope 0.667448, intercept -0.000000, loss 0.554513
```

Los tres alcanzan la forma cerrada hasta seis decimales, y el descenso simple llega primero. En un cuenco redondo con una tasa de aprendizaje bien elegida no hay nada que el momento pueda acumular ni nada que Adam pueda reescalar; ambos solo añaden su propia dinámica encima de un problema que no la necesitaba. El valle de Rosenbrock y este cuenco son los dos extremos de la misma historia, y en qué extremo estás es una propiedad del problema, no del optimizador.

## Ejercicios

1. ¿Cuál es la mayor tasa de aprendizaje del descenso simple que aún llega al valle en 5000 pasos?
2. ¿Cuántas evaluaciones del objetivo cuesta un gradiente ausente a lo largo de 200 pasos de Adam?
3. ¿Cómo cambia el coeficiente de momento el número de pasos?

<details>
<summary>Soluciones</summary>

Están en [`examples/l08_exercises.rs`](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/examples/l08_exercises.rs).

**1.** 0,002 — y el borde es afilado:

```text
== plain descent on Rosenbrock, 5000 steps, by learning rate
  rate 0.0001 : ends at f 2.305718
  rate 0.0005 : ends at f 0.042952
  rate 0.001  : ends at f 0.003761
  rate 0.002  : ends at f 0.000055
  rate 0.005  : ends at f 0.788039
  rate 0.01   : ends at f NaN
```

Por debajo de 0,002 la ejecución es estable y lenta; en 0,002 es estable y mucho más rápida; en 0,005 es inestable pero aún acotada; en 0,01 se ha ido. La ventana utilizable abarca un factor de unos cinco, y nada salvo probar te dice dónde está. Adam a 0,05 estaba cómodamente en medio de una mucho más ancha.

**2.** Cinco veces más:

```text
== evaluations of f for 200 Adam steps
  written gradient true : 201 evaluations, best f 2.588e0
  written gradient false: 1001 evaluations, best f 2.588e0
```

201 es una por paso más la primera. 1001 es eso más `2 × 2 coordenadas × 200 pasos`. Con `d` parámetros el factor es `1 + 2d`, así que un modelo con mil parámetros pagaría dos mil veces más — y llegaría al mismo punto, como muestra la columna `best f`.

**3.** Más momento ayuda hasta que deja de hacerlo:

```text
== momentum coefficient against steps to reach f < 1e-10
  0    : 20000 steps, last [0.9999, 0.9997] f 1.938e-8
  0.5  : 20000 steps, last [1.0000, 1.0000] f 2.130e-15
  0.9  :  4129 steps, last [1.0000, 1.0000] f 1.244e-16
  0.95 :  1790 steps, last [1.0000, 1.0000] f 1.242e-16
  0.99 :  4014 steps, last [1.0000, 1.0000] f 4.696e-18
```

Con `β = 0` esto es descenso simple, y 20 000 pasos no bastan para disparar la prueba sobre la norma del gradiente. 0,95 es el mejor de estos, con 1790 pasos. Con 0,99 la velocidad lleva tan lejos más allá del giro que la ejecución tarda más del doble — y aterriza en el punto más preciso de los cinco, tras haber espiraleado hacia dentro. Los valores por defecto habituales, 0,9 y 0,99, quedan a ambos lados del óptimo aquí, lo que da una imagen justa de cuánto merece la pena ajustar este parámetro.

</details>

## Fuentes

- Rosenbrock, *[An automatic method for finding the greatest or least value of a function](https://academic.oup.com/comjnl/article/3/3/175/345501)*, 1960
- Kingma y Ba, *[Adam: A Method for Stochastic Optimization](https://arxiv.org/abs/1412.6980)*, 2015
- Goodfellow, Bengio, Courville, *[Deep Learning](https://www.deeplearningbook.org/)*, capítulo 8
- Kirkpatrick, Gelatt y Vecchi, *[Optimization by Simulated Annealing](https://www.science.org/doi/10.1126/science.220.4598.671)*, 1983
- [PyTorch: `torch.optim`](https://docs.pytorch.org/docs/stable/optim.html)
- IX en `490c395`: [`ix-optimize/src/gradient.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-optimize/src/gradient.rs), [`ix-optimize/src/traits.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-optimize/src/traits.rs), [`ix-optimize/src/annealing.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-optimize/src/annealing.rs), [`ix-optimize/src/pso.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-optimize/src/pso.rs), [`ix-math/src/calculus.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-math/src/calculus.rs)
