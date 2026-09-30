---
title: "14. Aprendizaje por refuerzo: bandidos y Q-learning"
description: "Los bandidos, Q-learning y SARSA frente al crate ix-rl de IX, con ocho predicciones escritas antes de la primera ejecución: siete se cumplen y una se cumple en parte. Los algoritmos se comportan como dicen los manuales; los contratos de IX se equivocan en el desempate, su trait Agent lee la fila equivocada y nunca aprende, y su muestreo de Thompson supone recompensas de varianza 1."
sidebar:
  order: 14
---

Hasta ahora, cada lección aprendió de datos que otra persona recogió. El aprendizaje por refuerzo recoge los suyos: un agente elige una acción, el mundo responde con una recompensa, y la siguiente elección usa lo que las recompensas enseñaron. El crate [`ix-rl`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl) de IX, fijado, tiene las dos familias clásicas. Los bandidos de varios brazos (`EpsilonGreedy`, `UCB1`, `ThompsonSampling`) repiten una misma elección. Q-learning y SARSA tabulares actúan sobre una `GridWorld`, donde cada elección lleva al agente a otro estado. Esta lección reproduce dos experimentos de [Sutton y Barto](http://incompleteideas.net/book/the-book-2nd.html) con los algoritmos de IX, mide el regret frente a la cota de Auer et al. y comprueba lo que promete el [`CONTRACTS.md`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/CONTRACTS.md) de IX.

Las ocho predicciones que prueba esta lección se [escribieron en el diario](../journal/#2026-09-30--lección-14-predicha-antes-de-medir) y se registraron antes de que existiera su código. [Los resultados](../journal/#2026-09-30--lección-14-medida) las siguen. Los experimentos están en [`rl.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/rl.rs), un test por predicción. [`l14_reinforcement.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/examples/l14_reinforcement.rs) imprime lo que miden. [`crosscheck.py`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/crosscheck/crosscheck.py) recalcula la iteración de valores, los brazos del banco de pruebas y la cota del regret con [numpy](https://numpy.org/doc/stable/).

## 1. Bandidos, a mano

Un bandido tiene k brazos. El brazo a paga una recompensa aleatoria cuya media μₐ el algoritmo no conoce. Tirar siempre del mejor brazo daría μ\* por paso; cada tirada del brazo a pierde en cambio Δₐ = μ\* − μₐ. El regret tras T tiradas es la suma de los Δ de los brazos tirados. Es el pseudo-regret: cuenta el coste esperado de cada elección y deja fuera la suerte de las recompensas.

El algoritmo estima cada μₐ con la media de las recompensas que ha pagado el brazo a. No necesita guardarlas: tras la n-ésima recompensa R,

Qₙ = Qₙ₋₁ + (R − Qₙ₋₁) / n

es la media acumulada. Los tres bandidos de IX se actualizan así ([`bandit.rs` 39-43](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/bandit.rs#L39-L43)). Solo difieren en cómo eligen.

## 2. ε-voraz y el banco de pruebas de 10 brazos

ε-voraz tira del brazo con la estimación más alta, salvo con probabilidad ε, cuando tira de uno al azar de forma uniforme. El banco de pruebas de Sutton y Barto (sección 2.3, figura 2.2) tiene 2000 tareas aleatorias. Cada una tiene 10 brazos cuyas medias se toman de N(0, 1) y cuyas recompensas se toman de N(media, 1), y cada una se juega durante 1000 pasos. `testbed` en `rl.rs` ejecuta en él el `EpsilonGreedy` de IX. Las muestras normales son sumas de doce uniformes menos seis. Como N(0, 1), tienen media 0 y varianza 1, y solo necesitan aritmética, así que Windows, Linux y macOS sacan los mismos números. La [lección 12](../12-autodiff/) mostró lo que el `sin` y el `cos` de una plataforma hacen con los dígitos impresos. Cada ε ve las mismas tareas y el mismo ruido (P6):

```text
== The 10-armed testbed: 2000 tasks, 1000 steps, sample averages
  epsilon   optimal arm, steps 1-100 / 401-500 / 901-1000      average reward, steps 1-100 / 401-500 / 901-1000
  0          33.5 %   35.9 %   35.9 %           0.967   1.038   1.042
  0.01       35.1 %   48.8 %   58.7 %           0.981   1.196   1.309
  0.1        42.1 %   74.7 %   80.0 %           1.016   1.346   1.372
  mean over the tasks of the best arm's mean: 1.538
```

El voraz (ε = 0) se queda con el primer brazo que paga bien: tiene el mejor brazo en cerca de un tercio de las tareas, y esa parte apenas se mueve tras los cien primeros pasos (del 33,5 % al 35,9 %). ε = 0,1 encuentra el mejor brazo el 80 % de las veces en el paso 1000. ε = 0,01 sigue subiendo. Son las curvas de la figura 2.2, y los intervalos de P6 se fijaron a partir de ella. La media del mejor brazo vale 1,538 en promedio sobre las tareas. El máximo esperado de 10 muestras de N(0, 1) es 1,539, y numpy, con los mismos números aleatorios, también obtiene 1,538.

## 3. Empates, y un NaN

Un argmax necesita una regla para los empates. [`CONTRACTS.md` 8 y 14](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/CONTRACTS.md#L8-L14) dicen que `EpsilonGreedy` y `QLearning` los deshacen «by FIRST occurrence (lowest index)». Ambos eligen con [`Iterator::max_by`](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.max_by), cuya documentación dice lo contrario: «If several elements are equally maximum, the last element is returned.» `UCB1` hace lo mismo (P1):

```text
== Ties
  new EpsilonGreedy, 10 arms, epsilon 0:       arm 9
  new QLearning, 4 actions, epsilon 0:         action 3
  UCB1, 5 arms, after reward 1 from each:      arm 4
  UCB1, 3 arms, the same:                      arm 2
```

Antes de cualquier recompensa todas las estimaciones valen 0, así que la primera tirada de un algoritmo voraz es el último brazo, no el primero. En el banco de pruebas no importa, porque el azar decide cuál es el mejor brazo. Quien confíe en el contrato y ponga un brazo por defecto en el índice 0, esperando que gane los empates, obtiene el último. El test tiene un control: con un máximo único en el índice 0, la misma llamada devuelve 0.

El mismo contrato dice, en la [línea 24](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/CONTRACTS.md#L24), que «NaN rewards corrupt `q_values` silently». La rama voraz compara las estimaciones con `partial_cmp(...).unwrap()`, y `partial_cmp` no tiene respuesta para NaN (P2):

```text
== A NaN reward on arm 0 of 3, then 100 selections
  epsilon 0: Panic("called `Option::unwrap()` on a `None` value")
  epsilon 1: Value
```

La corrupción solo es silenciosa mientras todas las tiradas exploran. La primera elección voraz entra en pánico.

## 4. UCB1, y cómo crece el regret

ε-voraz explora al mismo ritmo para siempre. Con los brazos 0,9, 0,8 y 0,7 de recompensas de Bernoulli (1 con probabilidad p, si no 0), una tirada de exploración cuesta (0 + 0,1 + 0,2)/3 = 0,1 de media, así que ε = 0,1 paga 0,01 por paso y su regret crece linealmente con T. UCB1 ([Auer, Cesa-Bianchi y Fischer](https://doi.org/10.1023/A:1013689704352)) cambia el azar por optimismo. Tira del brazo con el valor más alto de

Qₐ + √(2 ln t / nₐ)

donde t es el número de tiradas hasta ahora y nₐ las del brazo a ([`bandit.rs` 62-81](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/bandit.rs#L62-L81)). Un brazo poco tirado tiene un bono grande y acaba probándose. Auer et al. demuestran que su regret esperado queda por debajo de 8 Σ ln T / Δₐ + (1 + π²/3) Σ Δₐ, una cota que crece como ln T. `mean_regret` promedia el pseudo-regret sobre 100 ejecuciones de 10⁴ pasos y 20 de 10⁵ (P7):

```text
== Regret on Bernoulli arms 0.9, 0.8, 0.7 (pseudo-regret, mean over runs)
        T   runs   epsilon-greedy 0.1     UCB1   Thompson (IX)   Auer et al. bound
    10000    100                113.2    146.3            85.4              1106.5
   100000     20               1016.6    278.6           141.9              1382.8
  regret(1e5) / regret(1e4): epsilon-greedy 8.98, UCB1 1.90, Thompson 1.66
```

Los 1016,6 de ε-voraz en 10⁵ están cerca de los 1000 que cuesta su exploración de media; el resto son errores voraces. Multiplicar T por 10 multiplicó su regret por 8,98, y el de UCB1 por 1,90, muy por debajo de la cota. La razón de UCB1 supera ln 10⁵ / ln 10⁴ = 1,25. Mi lectura, no una medida: con 10⁴ pasos, el propio bono del mejor brazo sigue siendo lo bastante grande para ocultar parte de las diferencias. Dos resultados no estaban predichos. Con 10⁴ pasos, ε-voraz va por delante de UCB1, y solo el horizonte más largo invierte el orden. El muestreo de Thompson de IX, la siguiente sección, tiene el menor regret en los dos horizontes.

## 5. El muestreo de Thompson y la escala de las recompensas

El muestreo de Thompson ([Thompson, 1933](https://doi.org/10.2307/2332286); [Agrawal y Goyal](https://proceedings.mlr.press/v23/agrawal12.html)) toma para cada brazo una media plausible según lo que cree, y tira del brazo cuya muestra es la más alta. Un brazo que conoce poco tiene una creencia ancha y a veces saca un valor alto. La versión de IX muestrea cada brazo de una normal con la media acumulada y varianza 1/n, y varianza 1 hasta la segunda tirada ([`bandit.rs` 112, 130-132](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/bandit.rs#L112-L132)). La normal viene de [`rand_distr`](https://docs.rs/rand_distr/0.5.1/rand_distr/struct.Normal.html). Es la creencia sobre una media tras n recompensas de varianza 1 sin previa, con N(0, 1) antes de la primera tirada. [`CONTRACTS.md` 13](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/CONTRACTS.md#L13) lo llama «a simplified update». Lo que no dice es que la varianza de las recompensas está fijada en 1, sean cuales sean. P8 hace pagar a los mismos brazos 0 o 1, o 0 o 100:

```text
== IX's Thompson sampling, arms paying 0 or 1 and 0 or 100: 100 runs of 10000 steps
  pay   1: one arm over 99 % of the pulls in 0 runs; most-pulled arm not the best in 0 runs
  pay 100: one arm over 99 % of the pulls in 100 runs; most-pulled arm not the best in 67 runs
```

Pagando 0 o 1, el modelo es aproximadamente correcto, y el muestreo de Thompson de IX ganó a UCB1 en la sección 4. Pagando 0 o 100, el primer brazo que paga toma una media cercana a 100p. Los demás siguen muestreando de normales de varianza como mucho 1 en torno a 0, así que nunca vuelven a tirarse. La ejecución se fija en el brazo que pagó primero, que es el mejor cerca del 0,9 / (0,9 + 0,8 + 0,7) = 37,5 % de las veces. Ocurrió en 33 ejecuciones de 100. Dividir las recompensas por su escala antes de `update` lo evita.

## 6. Estados: iteración de valores y Q-learning

Con estados, una acción también mueve al agente, y una buena acción ahora puede llevar a un mal sitio más tarde. El valor de la acción a en el estado s, seguida del mejor comportamiento posible, cumple la ecuación de Bellman:

Q\*(s, a) = r(s, a) + γ maxₐ′ Q\*(s′, a′)

donde s′ es adonde lleva a, r la recompensa, y γ < 1 descuenta las recompensas futuras. La [`GridWorld`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/env.rs#L10-L77) de IX es una cuadrícula de 5 × 5. Cada paso cuesta −1, llegar a la meta (4, 4) desde el inicio (0, 0) paga +10, y un paso contra una pared deja al agente donde está. `value_iteration` en `rl.rs` resuelve la ecuación a mano. La aplica a cada estado y cada acción, una y otra vez, hasta que nada cambia. El camino más corto tiene 8 pasos, siete a −1 y luego +10, así que V\*(inicio) = 10γ⁷ − (1 − γ⁷)/(1 − γ).

Q-learning ([Watkins y Dayan](https://doi.org/10.1007/BF00992698)) no conoce las reglas. Aprende los mismos valores a partir de sus propios movimientos, uno a uno:

Q(s, a) ← Q(s, a) + α (r + γ maxₐ′ Q(s′, a′) − Q(s, a))

Es el `update_index` de IX ([`q_learning.rs` 61-82](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/q_learning.rs#L61-L82)), y `train_gridworld` encadena los episodios con movimientos ε-voraces (P4):

```text
== Q-learning on the 5 x 5 GridWorld: learning rate 0.1, gamma 0.99, epsilon 0.1, 2000 episodes
  V*(start) by value iteration: 2.527188; 10 g^7 - (1 - g^7)/(1 - g): 2.527188
  max_a Q(start) after training: 2.527188
  |max_a Q(start) - V*(start)| below 1e-3: true
  largest |Q - Q*| over the 96 state-actions outside the goal: 8.484
  mean reward per episode: episodes 1-100 -4.38, 1901-2000 2.13
  greedy walk, rows from state_index:        8 steps
  greedy walk through Agent::select_action:  no path within 100 steps
```

El valor del inicio coincide con V\* hasta la sexta cifra decimal, y el recorrido voraz da los 8 pasos. La iteración de valores de numpy da el mismo 2,527188. La tabla entera es otra cosa: una entrada sigue a 8,484 de Q\*. El teorema de convergencia de Watkins y Dayan exige que cada estado y cada acción se prueben infinitas veces. Una acción que la política voraz evita solo se actualiza cuando la exploración la elige, como mucho un cuarto de ε, el 2,5 % de las visitas. Los valores a lo largo del camino convergen, y el resto de la tabla se queda atrás. La última línea corresponde a la sección 8.

## 7. SARSA, Q-learning y el acantilado

El acantilado de Sutton y Barto (ejemplo 6.6) es una cuadrícula de 4 × 12. El inicio y la meta están en los dos extremos de la fila de abajo, con el acantilado entre ellos. Cada paso cuesta −1, y un paso al acantilado cuesta −100 y devuelve al agente al inicio. SARSA difiere de Q-learning en un solo término:

Q(s, a) ← Q(s, a) + α (r + γ Q(s′, a′) − Q(s, a))

donde a′ es la acción que tomará de verdad a continuación, exploraciones incluidas. Q-learning aprende los valores de la política voraz. SARSA aprende los de la política ε-voraz que sigue, y con ella, ir por el borde significa caerse de vez en cuando. El `Sarsa` de IX tiene `update_index` y `select_action_index`, pero ni bucle de entrenamiento ni constructor. `cliff_sarsa` escribe el bucle y fija los campos públicos. Los dos algoritmos se ejecutan con γ = 1, un paso de 0,5 y ε = 0,1, en 50 ejecuciones de 500 episodios (P5):

```text
== The cliff: gamma 1, step 0.5, epsilon 0.1, 50 runs of 500 episodes
  greedy path, Q-learning: 13 steps: 50
  greedy path, SARSA:      no path: 12, 17 steps: 34, 19 steps: 3, 21 steps: 1
  mean online return, episodes 101-500: Q-learning -50.3, SARSA -27.5
  SARSA's walks with no path: stays in one cell, against a wall: 9; cycles through 2 cells: 3
```

Q-learning encontró el camino de 13 pasos junto al borde en las 50 ejecuciones. Mientras aprende, obtiene −50,3 por episodio, porque sus pasos de exploración junto al acantilado caen en él. SARSA obtiene −27,5. Su camino voraz tiene 17 pasos, la longitud del camino por la fila de arriba, en 34 ejecuciones, y más en 4. La figura del ejemplo 6.6 de Sutton y Barto muestra el mismo orden. Dos de las tres partes de P5 se cumplieron.

La tercera no: decía que el camino voraz de SARSA supera los 13 pasos en al menos 40 ejecuciones. Lo hace en 38. En las otras 12, el recorrido voraz leído de la tabla final de SARSA nunca llega a la meta. En 9 se queda en una casilla chocando contra una pared, y en 3 va y viene entre dos casillas. La predicción suponía que la tabla final describe un camino. Con un paso constante de 0,5 es una instantánea de estimaciones que siguen moviéndose. Mi explicación, no medida: una caída de exploración lleva la estimación de una casilla vecina a mitad de camino de un objetivo cercano a −100, lo que puede hacer que chocar contra una pared parezca mejor durante un tiempo. La figura de Sutton y Barto trata del retorno en línea, y esa parte se cumplió. P5 queda marcada como refutada en parte. Su test fija los 38 y 12 medidos, para que cualquier cambio se vea.

## 8. El trait Agent

[`traits.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/traits.rs#L16-L27) define un trait `Agent<E>` al que podría llamar un bucle de entrenamiento genérico, y `QLearning` lo implementa para `GridWorld`. `select_action` calcula la fila como r × `q_table.ncols()` + c ([`q_learning.rs` 123](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/q_learning.rs#L123)). Las columnas de la tabla Q son las 4 acciones, no las columnas de la cuadrícula. `update` está vacío ([`q_learning.rs` 133-142](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/q_learning.rs#L133-L142)). `rows_read` encuentra la fila que lee cada estado marcando una fila cada vez (P3):

```text
== The Agent trait on GridWorld
  5 x 5: states reading another state's row: 20; rows read twice: [4, 8, 12, 16]; rows never read: [21, 22, 23, 24]
  4 x 4: states reading another state's row: 0; rows read twice: []; rows never read: []
  row read by state (r, c) of the 5 x 5 grid:
    r = 0:  0  1  2  3  4
    r = 1:  4  5  6  7  8
    r = 2:  8  9 10 11 12
    r = 3: 12 13 14 15 16
    r = 4: 16 17 18 19 20
  largest |change| of the table after 1000 transitions, Agent::update: 0, exactly
  the same transitions through update_index:                         0.546
```

En una cuadrícula de 4 casillas de ancho, el error es invisible. En la de 5 × 5, el estado (r, c) lee la fila del estado situado r puestos antes en el orden de lectura, así que cada estado bajo la primera fila lee la de otro. La tabla entrenada en la sección 6, leída a través del trait, no llega a la meta en 100 pasos. Un bucle genérico escrito para `Agent` obtendría un agente que lee los estados equivocados y nunca aprende.

## 9. Las predicciones, puntuadas

| | Predicción, escrita antes de la primera ejecución | Medido | Veredicto |
|---|---|---|---|
| P1 | Los empates van al último índice: brazo 9 de 10, acción 3 de 4, brazo 4 de 5 en UCB1 | 9, 3 y 4 | Confirmada |
| P2 | Tras una recompensa NaN, una elección voraz entra en pánico; con ε = 1, 100 elecciones no | Pánico con ε = 0, no con ε = 1 | Confirmada |
| P3 | Con `Agent`, 20 de 25 estados leen otra fila, las filas 4, 8, 12, 16 dos veces, las 21–24 nunca; 4 × 4 todo bien; `update` no cambia nada | Como se predijo; cambio 0, exactamente | Confirmada |
| P4 | Q-learning: max Q(inicio) a menos de 10⁻³ de V\*(inicio) = 2,5272, camino voraz de 8 pasos | 2,527188; 8 pasos | Confirmada |
| P5 | Acantilado: Q-learning junto al borde en ≥ 45 ejecuciones; SARSA más de 13 pasos en ≥ 40; retorno en línea de SARSA mayor en ≥ 10 | 50; **38**; 22,8 | **Refutada en parte** |
| P6 | Banco de pruebas, pasos 901–1000: brazo óptimo 25–45 % con ε = 0, 70–90 % con ε = 0,1, ε = 0,01 entre ambos; recompensas en el mismo orden | 35,9 %, 80,0 %, 58,7 %; 1,042 < 1,309 < 1,372 | Confirmada |
| P7 | Regret de ε-voraz en 10⁵ en [990, 1200], razón 10⁵/10⁴ en [6; 10,5]; razón de UCB1 en [1,3; 3], por debajo de la cota de Auer et al. | 1016,6 y 8,98; 1,90, por debajo en ambos horizontes | Confirmada |
| P8 | Pagando 0 o 100, Thompson da a un brazo > 99 % de las tiradas en cada ejecución, no el mejor en 45–75; pagando 0 o 1, el mejor brazo es el más tirado en ≥ 90 | 100 y 67; 100 | Confirmada |

Siete se cumplieron en la primera ejecución. P5 se cumplió en dos de sus tres partes, y ningún intervalo se cambió después. P1, P2 y P3 se escribieron leyendo el código y los contratos de IX, para atrapar una diferencia entre lo que dicen y lo que hace el código, y cada una encontró una. P6 y P5 se fijaron a partir de las figuras de Sutton y Barto, y P4, P7 y P8 con cálculos. Los controles muestran que cada comprobación puede fallar: un máximo único sí gana, una recompensa normal no provoca pánico, `update_index` sí cambia la tabla, una tabla sin entrenar no encuentra camino, y pagar 0 o 1 no fija nada.

## Qué usar en nuestros repositorios

- **`EpsilonGreedy` y `UCB1` de IX:** hacen lo que dicen los manuales. Los empates van al último índice, diga lo que diga `CONTRACTS.md`: pon al final el brazo que debe ganar los empates, o deshazlos antes de llamar. Comprueba que una recompensa no sea NaN antes de `update`.
- **`ThompsonSampling` de IX:** solo para recompensas de varianza cercana a 1. Si no, reescálalas, o puede quedarse fijo en el primer brazo que pague.
- **Horizontes largos:** UCB1 o el muestreo de Thompson. Con un ε fijo, el regret de ε-voraz sigue creciendo linealmente.
- **`QLearning` de IX:** `select_action_index`, `update_index` y `train_gridworld` son correctos. No uses su implementación de `Agent`.
- **SARSA con IX:** escribe tú el bucle, júzgalo por su retorno en línea, y comprueba que un camino voraz leído de su tabla llega a la meta antes de usarlo.

## Ejercicios

1. Demuestra que la actualización Qₙ = Qₙ₋₁ + (Rₙ − Qₙ₋₁)/n, desde cualquier Q₀, da la media de R₁, …, Rₙ.
2. ε-voraz con ε = 0,1 sobre los brazos 0,9, 0,8 y 0,7: ¿cuánto cuesta la exploración por paso, y qué regret esperas tras 10⁶ pasos?
3. Con recompensas de 0 o 100, ¿por qué la primera tirada del `ThompsonSampling` de IX es uniforme sobre los brazos, y por qué lo sigue siendo tras un fallo? ¿Por qué 37,5 % es solo una aproximación de la probabilidad de fijarse en el mejor brazo?
4. ¿Qué necesitaría `Agent::select_action` de `QLearning` para leer la fila correcta, y por qué no puede calcularlo a partir de sus argumentos?

<details>
<summary>Soluciones</summary>

1. La primera actualización da Q₁ = Q₀ + (R₁ − Q₀)/1 = R₁, sea cual sea Q₀. Después, por inducción, si Qₙ₋₁ = (R₁ + … + Rₙ₋₁)/(n − 1), entonces Qₙ = Qₙ₋₁(1 − 1/n) + Rₙ/n = ((n − 1)Qₙ₋₁ + Rₙ)/n = (R₁ + … + Rₙ)/n.
2. Una tirada de exploración elige cada brazo con probabilidad 1/3, así que cuesta (0 + 0,1 + 0,2)/3 = 0,1 de media, y exploran ε = 0,1 de las tiradas: 0,01 por paso. Tras 10⁶ pasos, unos 10 000, más unas decenas de errores voraces; P7 midió 1016,6 tras 10⁵.
3. Antes de cualquier tirada, cada brazo muestrea de N(0, 1), así que todos tienen la misma probabilidad de sacar el valor más alto. Tras un fallo, un brazo tiene n = 1 y su varianza sigue en 1 (IX solo la actualiza cuando n > 1), con media 0, así que sigue muestreando de N(0, 1). El primer brazo que paga se fija entonces, con una probabilidad proporcional a su p mientras cada tirada sea uniforme. Tras un segundo fallo del mismo brazo, su varianza baja a 1/2 y gana el sorteo con menos frecuencia. Eso exige dos fallos seguidos antes de cualquier éxito, algo raro pero no imposible.
4. Necesitaría el ancho de la cuadrícula: la fila de (r, c) es r × ancho + c. El trait solo pasa el estado (r, c), y la tabla Q conoce el número de estados y de acciones, no la forma de la cuadrícula: 25 estados pueden ser 5 × 5 o 1 × 25. El agente tendría que guardar el ancho al construirse para una cuadrícula, o el trait tendría que recibir el entorno.

</details>

## Fuentes

- IX en el commit fijado `490c395`: [`bandit.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/bandit.rs), [`q_learning.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/q_learning.rs), [`env.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/env.rs), [`traits.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/traits.rs) y [`CONTRACTS.md`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/CONTRACTS.md).
- R. S. Sutton y A. G. Barto, [*Reinforcement Learning: An Introduction*](http://incompleteideas.net/book/the-book-2nd.html), 2.ª edición, MIT Press, 2018: capítulo 2 para los bandidos y el banco de pruebas, capítulo 6 para Q-learning, SARSA y el acantilado.
- P. Auer, N. Cesa-Bianchi y P. Fischer, [«Finite-time analysis of the multiarmed bandit problem»](https://doi.org/10.1023/A:1013689704352), Machine Learning 47, 2002: UCB1 y su cota.
- C. J. C. H. Watkins y P. Dayan, [«Q-learning»](https://doi.org/10.1007/BF00992698), Machine Learning 8, 1992.
- W. R. Thompson, [«On the likelihood that one unknown probability exceeds another in view of the evidence of two samples»](https://doi.org/10.2307/2332286), Biometrika 25, 1933.
- S. Agrawal y N. Goyal, [«Analysis of Thompson sampling for the multi-armed bandit problem»](https://proceedings.mlr.press/v23/agrawal12.html), COLT 2012.
- La biblioteca estándar de Rust, [`Iterator::max_by`](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.max_by).
