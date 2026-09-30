---
title: "17. Evolución: algoritmos genéticos, evolución diferencial, frentes de Pareto"
description: "La selección, el cruce BLX y la mutación, el algoritmo genético y la evolución diferencial de IX, y los frentes de Pareto frente a ix-evolution, con ocho predicciones escritas antes de la primera ejecución, siete confirmadas y una refutada en parte. El AG de IX baja de la pérdida objetivo de minimize_linreg_mse tras una mediana de 916 evaluaciones, de cinco a diez veces menos de lo que afirma el ejemplo; su tasa de mutación es una desviación típica, devuelve su última generación cuando el elitismo está desactivado, su evolución diferencial nunca termina con tres individuos, y su frontera de Pareto informa del error de una tabla rechazada de un modo que depende del orden."
sidebar:
  order: 17
---

Un algoritmo evolutivo mantiene una población de soluciones candidatas y la mejora imitando la selección. Cruza a los mejores candidatos, mezcla sus genes, perturba el resultado y repite. No necesita ningún gradiente, solo una puntuación para cada candidato. El crate fijado [`ix-evolution`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution) de IX tiene tres operadores de selección, un algoritmo genético de codificación real, la evolución diferencial y una ordenación no dominada para problemas con varios objetivos. Esta lección mide cada parte y luego ejecuta el algoritmo genético sobre la pérdida que el Adam de la [lección 12](../12-autodiff/) minimizó en 31 pasos, porque el ejemplo de IX afirma un número para él.

Las ocho predicciones que pone a prueba esta lección se [escribieron en el diario](../journal/#2026-09-30--lección-17-predicha-antes-de-medir) y se confirmaron en un commit antes de que existiera su código. [Los resultados](../journal/#2026-09-30--lección-17-medida) las siguen. Los experimentos están en [`evolution.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/evolution.rs), una prueba por predicción, y [`l17_evolution.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/examples/l17_evolution.rs) imprime lo que miden. Los operadores de IX aceptan cualquier [`rand::Rng`](https://docs.rs/rand/0.9.5/rand/trait.Rng.html), así que el curso les pasa su propio flujo splitmix64. [`crosscheck.py`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/crosscheck/crosscheck.py) reconstruye los conjuntos de Pareto de la lección a partir de ese flujo y comprueba la fórmula del cruce con el generador de numpy.

## 1. La selección

La selección decide qué candidatos pasan a ser padres. Los tres operadores de IX minimizan ([`selection.rs` 7-69](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/selection.rs#L7-L69)):

- `tournament` extrae k candidatos con reemplazo y se queda con el mejor. Con 3 candidatos y k = 3, el mejor gana salvo que las tres extracciones lo fallen: 1 − (2/3)³ = 19/27. [Blickle y Thiele (1996)](https://doi.org/10.1162/evco.1996.4.4.361) comparan estos esquemas.
- `rank` ordena los candidatos y extrae con peso n para el mejor hasta 1 para el peor, sean cuales sean los valores de aptitud.
- `roulette` extrae con una probabilidad proporcional a max − f + 10⁻¹⁰, así que el peor candidato siempre pesa 10⁻¹⁰.

P1 extrae 100 000 veces de las aptitudes [0, 1, 2], luego [0, 1, 1000] y [0, 1]:

```text
== selection, 100000 draws each (best, middle, worst)
  tournament, k = 3, on [0, 1, 2]:  0.7027 0.2607 0.0366   (19/27, 7/27, 1/27)
  rank on [0, 1, 2]:                0.5027 0.3321 0.1652   (3/6, 2/6, 1/6)
  roulette on [0, 1, 2]:            0.6657 0.3342 0.0000   (2/3, 1/3, 0)
  roulette on [0, 1, 1000]:         0.5009 0.4991 0.0000   (1000/1999, 999/1999, 0)
  roulette on [0, 1]:               1.0000 0.0000
  roulette drew the worst 0 times
```

Cada frecuencia está a menos de 0,006 de su valor. `roulette` hace lo que dice su comentario, «fitness-proportional, for minimization», y el desplazamiento por el máximo tiene consecuencias que conviene conocer. El peor candidato nunca se extrae. Un valor atípico en 1000 deja al mejor y al segundo casi iguales. De dos candidatos, el mejor se extrae siempre. `tournament` y `rank` solo dependen del orden de las aptitudes, así que la escala no les importa.

## 2. El cruce y la mutación

`RealIndividual::crossover` es el BLX-α de [Eshelman y Schaffer (1993)](https://doi.org/10.1016/B978-0-08-094832-4.50018-0). Cada gen del hijo se extrae uniformemente en [min − αd, max + αd], donde d es la distancia entre los genes de los dos padres y α = 0,5 ([`traits.rs` 43-52](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/traits.rs#L43-L52)). Su efecto sobre la dispersión de una población se deduce en dos líneas. Tomemos padres extraídos independientemente de una población de varianza σ². La media del hijo es el punto medio, de varianza σ²/2. Alrededor de él, el hijo es uniforme en una anchura de (1 + 2α)d, una varianza de (1 + 2α)²d²/12, y E[d²] = 2σ². La varianza del hijo es por tanto σ²/2 + (1 + 2α)²σ²/6. Eso da 7σ²/6 con α = 0,5, y exactamente σ² con α = (√3 − 1)/2 ≈ 0,366. P2 cruza 200 pares de padres de 1000 genes cada uno. Los padres vienen de la normal aproximada del curso: la suma de doce uniformes menos seis, de varianza exactamente 1. La deducción solo necesita la independencia y la varianza.

```text
== BLX-0.5 crossover, 200 pairs of parents with 1000 genes each
  parents' variance 1.0013, children's variance 1.1639 (7/6 = 1.1667); every child gene inside its interval: true
```

El cruce por sí solo ensancha la población en un sexto cada generación, y la selección tiene que tirar en sentido contrario. La comprobación cruzada repite el experimento con numpy y encuentra 1,169 con α = 0,5 y 1,002 con α = 0,366.

`Individual::mutate` está documentada como «Mutate in place with given mutation rate» ([`traits.rs` 13-14](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/traits.rs#L13-L14)). En los términos de [Eiben y Smith](https://doi.org/10.1007/978-3-662-44874-8), una tasa de mutación es la probabilidad de que un gen mute, y el tamaño de un cambio gaussiano es un paso, σ. `RealIndividual`, en cambio, elige cada gen con una probabilidad fija de 0,3 y le suma N(0, rate) ([`traits.rs` 54-62](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/traits.rs#L54-L62)). La tasa es una desviación típica. El [`Normal::new`](https://docs.rs/rand_distr/0.5.1/rand_distr/struct.Normal.html#method.new) de rand_distr solo rechaza una desviación típica no finita. P3 muta 100 000 genes en 0:

```text
== mutate(rate) on 100000 genes at 0
  rate  0.1: fraction changed 0.3010, standard deviation of the changes 0.1009
  rate    1: fraction changed 0.3010, standard deviation of the changes 1.0093
  rate -0.1: fraction changed 0.3010, standard deviation of the changes 0.1009
  rate    0: fraction changed 0.0000, standard deviation of the changes 0.0000
  rate  NaN: panic "called `Result::unwrap()` on an `Err` value: BadVariance"
```

La misma semilla elige los mismos genes, así que la fracción es la misma para cada tasa, y diez veces la tasa da diez veces los cambios. Quien fija una tasa de 0,01, queriendo decir «un gen de cada cien», ve moverse el 30 % de los genes en torno a 0,01. Una tasa negativa equivale a su opuesta, y NaN provoca un pánico en la primera generación.

## 3. El algoritmo genético y el elitismo

`GeneticAlgorithm::minimize` extrae una población uniformemente dentro de los límites. En cada generación la ordena, registra la mejor aptitud en `fitness_history` y copia sin cambios los `elitism` mejores candidatos. Completa el resto con hijos: dos ganadores de torneo, cruzados con probabilidad 0,8, mutados, recortados a los límites y evaluados. El resultado es el mejor de la población final ([`genetic.rs` 85-139](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/genetic.rs#L85-L139)). Con el `elitism` por defecto de 2, el mejor candidato siempre sobrevive, y el mejor final es el mejor visto nunca. `elitism` es un campo público. Con 0, nada transmite al mejor. P4 ejecuta los valores por defecto sobre la esfera Σxᵢ² en dimensión 3, con elitismo 0 y 2:

```text
== IX's GA on the sphere in 3 dimensions, 20 seeds, its defaults except elitism
  elitism 0: returned fitness above the best recorded for 20 of 20; history rises for 20
             median returned 2.37e-5, median best recorded 5.73e-7
  elitism 2: history never rises and returned at most its last entry for 20 of 20
             median returned 1.87e-8
```

Sin elitismo, cada ejecución devuelve un candidato peor que uno que ya había encontrado, y la mediana de la aptitud devuelta es 41 veces la mediana del mejor registrado. Es una elección de quien llama, pero `best_fitness` no dice que significa «el mejor de la última generación».

## 4. Cuántas evaluaciones, frente a Adam

El ejemplo [`minimize_linreg_mse`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/examples/minimize_linreg_mse.rs#L173-L181) de IX entrena una regresión lineal con Adam y luego imprime que «ix-evolution GA on a similar 4-parameter optimum typically needs ~5000-10000 fitness evaluations to reach the same loss», y una aceleración de 7500 dividido por el número de pasos de Adam. No se ejecuta ningún algoritmo genético ([lección 12](../12-autodiff/)). P5 ejecuta uno. El objetivo es el error cuadrático medio del ejemplo sobre (w₀, w₁, w₂, b), reconstruido en la lección 12, y cada ejecución cuenta sus evaluaciones hasta que la pérdida baja por primera vez de 0,01, el objetivo de Adam. Los valores por defecto de IX evalúan 100 + 500 × 98 = 49 100 veces por ejecución. [`DifferentialEvolution`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/differential.rs), en la sección 5, se ejecuta sobre la misma pérdida con sus propios valores por defecto.

```text
== minimize_linreg_mse's loss over (w0, w1, w2, b): evaluations until it first falls below 0.01, 20 seeds
  GA, defaults: 49100 evaluations per run, below 0.01 in 20 of 20 runs, first after a median of 916.0 (min 485, max 1356)
      final loss, median 2.34e-7
  DE, defaults: 50050 evaluations per run, below 0.01 in 20 of 20 runs, first after a median of 1250.0 (min 496, max 1715)
      final loss, median 1.81e-13
  Adam, lesson 12: below 0.01 at step 31
```

P5 predijo que cada ejecución llegaría, lo que se cumplió, y se equivocó dos veces. La mediana del AG es de 916 evaluaciones, por debajo del intervalo predicho de 1000 a 10 000. Eso son unas 8 generaciones tras las 100 primeras, donde un modelo aproximado de la dispersión de la población predecía de 20 a 60. La evolución diferencial necesita más evaluaciones para llegar, no menos. La cifra del ejemplo es de 5,5 a 11 veces la mediana del AG, y la aceleración que imprime, 242, sería 916 / 31 ≈ 30. Una razón probable de la rapidez del AG aquí, no medida, es la colinealidad de las variables de la lección 12. La pérdida es plana en una dirección, así que la región por debajo de 0,01 es una losa alargada más que una bola pequeña. El diario lo anota como por verificar. Los dos métodos también terminan de forma distinta. DE es más lenta en llegar a 0,01 y luego termina 6 órdenes de magnitud por debajo del AG. Una razón probable, tampoco medida: los pasos de DE se reducen con la dispersión de la población, mientras que el 76 % de los hijos del AG (1 − 0,7⁴) reciben al menos un cambio de tamaño fijo 0,1.

## 5. La evolución diferencial

El DE/rand/1/bin de [Storn y Price (1997)](https://doi.org/10.1023/A:1008202821328) construye para cada objetivo un mutante a partir de otros tres candidatos, x_r1 + F(x_r2 − x_r3). Cruza el mutante con el objetivo gen a gen con probabilidad CR y conserva la prueba si no puntúa peor. El vector diferencia da a cada paso la escala y la dirección de la propia población. La versión de IX sustituye los objetivos sobre la marcha, como hace por defecto el [`differential_evolution`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.optimize.differential_evolution.html) de SciPy (`updating='immediate'`). Necesita tres candidatos distintos del objetivo. `pick_three` vuelve a extraer hasta tenerlos, y nada comprueba que existan ([`differential.rs` 132-146](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/differential.rs#L132-L146)). P6 ejecuta `minimize` en un hilo y espera 2 segundos:

```text
== DifferentialEvolution::minimize in a thread, 10 generations, waited for 2 s
  3 individuals: returned false
  4 individuals: returned true
```

Con 3 candidatos, el tercer índice nunca se encuentra, y el bucle gira hasta que termina el proceso. Hace falta una población de al menos 4, e IX no lo comprueba.

## 6. Los frentes de Pareto

Con varios objetivos, un candidato domina a otro cuando no es peor en ningún objetivo y es mejor en al menos uno. Los candidatos a los que nadie domina forman el primer frente de Pareto. Quitarlo y repetir da los frentes siguientes. `pareto::rank` es la ordenación no dominada rápida de [Deb et al. (2002)](https://doi.org/10.1109/4235.996017) ([`pareto.rs` 71-130](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/pareto.rs#L71-L130)). Cuenta los dominadores de cada candidato, retira los que no tienen ninguno y decrementa. Para n puntos extraídos uniformemente, [Bentley et al. (1978)](https://doi.org/10.1145/322092.322095) dan el tamaño esperado del primer frente: H_n = Σ 1/k en dimensión 2, y Σ H_k/k en dimensión 3. En dimensión 2 es el número de récords de una permutación aleatoria, cuya varianza es H_n − Σ 1/k² ([Knuth](https://www-cs-faculty.stanford.edu/~knuth/taocp.html), sección 1.2.10). P7 clasifica 100 conjuntos de 200 puntos y compara cada frente con un pelado por fuerza bruta:

```text
== pareto::rank on 100 sets of 200 uniform points, every objective minimized
  2 dimensions: mean size of front 0 6.220 (expected 5.878); all fronts equal to brute force 100 of 100; unchanged with the rows reversed 100 of 100
  3 dimensions: mean size of front 0 17.810 (expected 18.096); all fronts equal to brute force 100 of 100; unchanged with the rows reversed 100 of 100
```

6,220 está a 1,7 errores típicos de 5,878, y 17,810 a 0,3 de 18,096. La comprobación cruzada reconstruye los mismos conjuntos y encuentra las mismas medias con numpy. En dimensión 3, el 9 % de los 200 puntos ya no está dominado. La proporción crece con el número de objetivos, hasta que la dominancia deja de distinguir a los candidatos.

## 7. La frontera de una tabla

`frontier` toma una tabla larga de filas (revisión, clase de tarea, candidato, métrica, dirección, valor). La valida, la pivota por (revisión, clase de tarea) y emite el frente 0. Su comentario hace una promesa cuidadosa: la salida es idéntica byte a byte sea cual sea el orden de las filas, y también el error de una tabla rechazada. Las comprobaciones «run in a fixed sequence and each scans the input in canonical sorted order» ([`frontier.rs` 183-188](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/frontier.rs#L183-L188)). El orden canónico es una ordenación estable por (revisión, clase de tarea, candidato, métrica) ([`frontier.rs` 195-196](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/frontier.rs#L195-L196)), así que dos filas con la misma clave conservan su orden de entrada. La comprobación de direcciones va antes que la de duplicados ([`frontier.rs` 347-372](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/frontier.rs#L347-L372)). P8 le da dos filas para un candidato y una métrica, escritas «min» y «Max»:

```text
== frontier on two rows for one candidate and metric, directions "min" and "Max"
  in that order: UnknownDirection "min"
  reversed:      UnknownDirection "Max"
  a valid table of 300 rows: 21 frontier rows, the same CSV for 50 of 50 shuffles
  IX's table with several defects: "candidate a in rev-a/t repeats metric cost", the same error for 50 of 50 shuffles
```

La tabla válida y la tabla de la propia prueba de IX cumplen su promesa. El hueco requiere dos filas que comparten clave y están mal escritas cada una a su manera: la comprobación de direcciones informa de la que llega primero. La prueba de IX ([`tests/frontier.rs` 500-524](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/tests/frontier.rs#L500-L524)) permuta una tabla cuyos duplicados comparten dirección, así que no podía verlo. Pasar primero la comprobación de duplicados, o incluir la dirección en la clave de ordenación, lo cerraría.

La cabecera del crate y la descripción de su paquete también anuncian programación genética ([`lib.rs` 1-4](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/lib.rs#L1-L4)). Ninguno de sus seis módulos la implementa.

## 8. Las predicciones, puntuadas

| | Predicción, escrita antes de la primera ejecución | Medido | Veredicto |
|---|---|---|---|
| P1 | Torneo 19/27 para el mejor de [0, 1, 2]; rango 3/6, 2/6, 1/6; ruleta 2/3, 1/3, 0, luego 1000/1999 en [0, 1, 1000] y siempre el mejor de dos; todo a menos de 0,006 | Como se predijo; la ruleta nunca extrajo al peor | Confirmada |
| P2 | BLX-0,5 multiplica la varianza por 7/6: 1,1667 ± 0,015, cada hijo dentro de su intervalo | 1,1639, todos dentro | Confirmada |
| P3 | El 30 % ± 0,5 % de los genes cambian con tasas 0,1 y 1, con una desviación típica a menos del 2 % de la tasa; −0,1 como 0,1; 0 no cambia nada; NaN provoca un pánico | 30,1 %, 0,1009 y 1,0093; como se predijo | Confirmada |
| P4 | Elitismo 0: aptitud devuelta por encima del mejor registrado para ≥ 18 de 20 semillas, el historial sube para 20; elitismo 2: nunca sube | 20, 20; 20 | Confirmada |
| P5 | Cada ejecución del AG y de DE baja de 0,01; mediana del AG entre 1000 y 10 000 evaluaciones; mediana de DE menor | 20 y 20 ejecuciones; AG 916; DE 1250 | Refutada en parte |
| P6 | DE con 3 individuos no ha terminado tras 2 s; con 4, termina | Como se predijo | Confirmada |
| P7 | Primer frente medio de 200 puntos uniformes en [5,22, 6,54] en 2D y [16,8, 19,4] en 3D; cada frente igual a la fuerza bruta; el orden de las filas no influye | 6,220 y 17,810; 100 de 100 | Confirmada |
| P8 | Dos filas mal escritas con una clave: «min» en un orden, «Max» al revés; tablas válidas y tabla de IX independientes del orden | Como se predijo | Confirmada |

Siete se cumplieron en la primera ejecución, y una quedó refutada en parte. El código compiló a la primera. No se cambió ningún intervalo después. P1, P2, P3 y P7 venían de deducciones y resultados publicados. P3, P4, P6 y P8 venían de leer el código de IX frente a sus comentarios, y las cuatro encontraron una discrepancia. P5 venía de un modelo aproximado, y el modelo se equivocó: el algoritmo genético alcanzó el objetivo en más o menos un tercio de las generaciones que le concedía. Su prueba fija ahora las medianas medidas. Los controles muestran que cada comprobación puede fallar. El elitismo 2 sí conserva al mejor. Cuatro individuos sí terminan. La tabla válida y la propia tabla de IX sí conservan su independencia del orden.

## Qué usar en nuestros repositorios

- **El `GeneticAlgorithm` de IX:** mantener `elitism` en 1 o más. Leer `mutation_rate` como la desviación típica de un cambio, a dimensionar según la escala de las variables. Alrededor del 30 % de los genes cambian, sea cual sea la tasa.
- **El `DifferentialEvolution` de IX:** comprobar que la población tiene al menos 4 candidatos antes de llamarlo, ya que IX no lo hace. Sobre esta pérdida terminó 6 órdenes de magnitud por debajo del AG.
- **Una pérdida suave con gradiente:** Adam llegó a 0,01 en 31 pasos, el AG en una mediana de 916 evaluaciones y DE en 1250. El 242× del ejemplo está más cerca de 30×.
- **La selección:** preferir `tournament` o `rank` cuando las aptitudes pueden incluir valores atípicos. `roulette` depende de la escala y nunca elige al peor.
- **`pareto::rank`:** exacto e independiente del orden de las filas; coincidió con la fuerza bruta en 200 conjuntos.
- **`frontier`:** determinista sobre una tabla válida. No basar nada en el texto de su error.

## Ejercicios

1. Deducir la varianza del hijo de BLX-α para padres independientes de varianza σ², y el α que la conserva.
2. En un torneo de tamaño k con reemplazo entre n candidatos de aptitudes distintas, mostrar que el i-ésimo mejor gana con probabilidad ((n − i + 1)/n)^k − ((n − i)/n)^k. Comprobar 19/27, 7/27 y 1/27 para n = k = 3.
3. Mostrar que para n puntos del plano con coordenadas distintas, el número de puntos no dominados (minimizando ambas) es igual al número de récords de una permutación, y deducir que su media es H_n.
4. ¿Por qué DE/rand/1 necesita al menos cuatro candidatos? Escribir la comprobación que le falta a `DifferentialEvolution::minimize`.

<details>
<summary>Soluciones</summary>

1. El hijo es m + U, donde m = (a + b)/2 y U es uniforme en una anchura de (1 + 2α)d centrada en m, con d = |a − b|. Var(m) = σ²/2. Dado d, Var(U) = (1 + 2α)²d²/12, y E[d²] = E[(a − b)²] = 2σ². U tiene media 0 dado (a, b), así que las varianzas se suman: σ²/2 + (1 + 2α)²σ²/6. Igualarla a σ² da (1 + 2α)² = 3, es decir α = (√3 − 1)/2 ≈ 0,366.
2. El i-ésimo mejor gana cuando cada extracción cae en el i-ésimo mejor o peor, lo que tiene probabilidad ((n − i + 1)/n)^k, y no todas son peores que el i-ésimo, lo que tiene probabilidad ((n − i)/n)^k. Para n = k = 3: 1 − 8/27 = 19/27, 8/27 − 1/27 = 7/27, y 1/27.
3. Ordenar los puntos por su primera coordenada, en orden creciente. Un punto está dominado si y solo si algún punto anterior tiene una segunda coordenada menor. Así que los puntos no dominados son aquellos cuya segunda coordenada es un nuevo mínimo, los récords de la sucesión de segundas coordenadas. Para puntos uniformes, esa sucesión está en orden aleatorio, y el k-ésimo valor es un récord con probabilidad 1/k. La media es Σ 1/k = H_n.
4. El mutante x_r1 + F(x_r2 − x_r3) requiere r1, r2 y r3 distintos y diferentes del objetivo i: cuatro índices distintos. Con 3 o menos, el último bucle de `pick_three` nunca termina. La comprobación es `assert!(self.population_size >= 4, "DE/rand/1 needs at least 4 individuals")`, o un error `Result`, al principio de `minimize`.

</details>

## Fuentes

- IX en el commit fijado `490c395`: [`selection.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/selection.rs), [`traits.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/traits.rs), [`genetic.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/genetic.rs), [`differential.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/differential.rs), [`pareto.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/pareto.rs), [`frontier.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/frontier.rs), y el [`minimize_linreg_mse.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/examples/minimize_linreg_mse.rs) de ix-autograd.
- L. J. Eshelman y J. D. Schaffer, [«Real-coded genetic algorithms and interval-schemata»](https://doi.org/10.1016/B978-0-08-094832-4.50018-0), Foundations of Genetic Algorithms 2, 1993.
- T. Blickle y L. Thiele, [«A comparison of selection schemes used in evolutionary algorithms»](https://doi.org/10.1162/evco.1996.4.4.361), Evolutionary Computation 4, 1996.
- R. Storn y K. Price, [«Differential evolution – a simple and efficient heuristic for global optimization over continuous spaces»](https://doi.org/10.1023/A:1008202821328), Journal of Global Optimization 11, 1997.
- K. Deb, A. Pratap, S. Agarwal y T. Meyarivan, [«A fast and elitist multiobjective genetic algorithm: NSGA-II»](https://doi.org/10.1109/4235.996017), IEEE Transactions on Evolutionary Computation 6, 2002.
- J. L. Bentley, H. T. Kung, M. Schkolnick y C. D. Thompson, [«On the average number of maxima in a set of vectors and applications»](https://doi.org/10.1145/322092.322095), Journal of the ACM 25, 1978.
- D. E. Knuth, [*The Art of Computer Programming*](https://www-cs-faculty.stanford.edu/~knuth/taocp.html), vol. 1, sección 1.2.10.
- A. E. Eiben y J. E. Smith, [*Introduction to Evolutionary Computing*](https://doi.org/10.1007/978-3-662-44874-8), 2.ª edición, Springer, 2015.
- SciPy: [`optimize.differential_evolution`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.optimize.differential_evolution.html). rand: [`Rng`](https://docs.rs/rand/0.9.5/rand/trait.Rng.html); rand_distr: [`Normal::new`](https://docs.rs/rand_distr/0.5.1/rand_distr/struct.Normal.html#method.new).
