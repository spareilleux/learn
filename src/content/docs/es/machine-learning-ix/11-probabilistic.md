---
title: "11. Contar sin contar: filtros de Bloom, HyperLogLog, count-min, cuco"
description: "Cuatro estructuras que responden a preguntas de pertenencia, cardinalidad y frecuencia en una memoria fijada de antemano, medidas en ix-probabilistic de IX frente a siete predicciones escritas antes de la primera ejecución: las siete se cumplieron, y dos de ellas revelan una cota documentada errónea y un filtro cuco que pierde un elemento."
sidebar:
  order: 11
---

Un conjunto con hash responde de forma exacta a "¿ya he visto esto?", y crece con cada elemento. Las cuatro estructuras del crate [`ix-probabilistic`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic) fijado de IX responden a esa pregunta y a otras dos en una memoria fijada de antemano. El precio es un error conocido y acotado. Esta lección mide ese error frente a las fórmulas que lo prometen.

Las siete predicciones que pone a prueba esta lección se [escribieron en el diario](../journal/#2026-09-29--lección-11-predicha-antes-de-medir) y se commitearon antes de que existiera una sola línea de su código. [Los resultados](../journal/#2026-09-29--lección-11-medida) vienen después. Los experimentos están en [`sketch.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/sketch.rs), con una prueba por predicción. [`l11_sketches.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/examples/l11_sketches.rs) imprime lo que miden. [`crosscheck.py`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/crosscheck/crosscheck.py) recalcula las fórmulas en Python y reproduce con numpy el HyperLogLog escrito a mano.

| Pregunta | Estructura | Tipo de IX | Error que admite |
|---|---|---|---|
| ¿Está este elemento en el conjunto? | Filtro de Bloom | `bloom::BloomFilter` | Falsos positivos, nunca falsos negativos |
| ¿Cuántos elementos distintos hay? | HyperLogLog | `hyperloglog::HyperLogLog` | Un error relativo de alrededor de 1,04/√m |
| ¿Cuántas veces apareció este elemento? | Count-min sketch | `count_min::CountMinSketch` | Solo sobreconteos, acotados con una probabilidad dada |
| ¿Está este elemento en el conjunto, con borrados? | Filtro cuco | `cuckoo::CuckooFilter` | Falsos positivos, e inserciones que pueden fallar |

Las cuatro usan el [`DefaultHasher`](https://doc.rust-lang.org/std/collections/hash_map/struct.DefaultHasher.html) de Rust. Es determinista para una versión dada de Rust, pero, como dice su documentación, no es estable entre versiones. Los elementos son los enteros 0, 1, 2, …, así que cada experimento da lo mismo en cada ejecución.

## 1. Un filtro de Bloom y sus falsos positivos

Un [filtro de Bloom](https://doi.org/10.1145/362686.362692) es un vector de m bits y k funciones hash. Insertar un elemento pone a 1 los k bits a los que apuntan sus hashes. Una consulta responde "quizá" cuando los k bits están a 1, y "no" en cuanto uno no lo está. Un elemento insertado siempre encuentra sus bits a 1: no hay falsos negativos. Un elemento no insertado puede encontrar sus k bits puestos a 1 por otros: es un falso positivo.

Para n elementos y una tasa objetivo p, los bits y hashes que minimizan la tasa son m = −n ln p / (ln 2)² y k = (m/n) ln 2. Con hashes aleatorios, la tasa tras n inserciones es entonces (1 − e^(−kn/m))^k. [`BloomFilter::new`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/bloom.rs#L31) usa las dos primeras fórmulas y redondea ambas hacia arriba. El dimensionamiento escrito a mano en `sketch.rs` encuentra el mismo m. El número de hashes de IX se lee en la forma serde del filtro, porque el campo es privado:

```text
== Bloom filter: new(10000, 0.01)
  hand sizing: m = 95851 bits, k = 7 hashes
  10000 inserted, IX m = 95851, k = 7: 0 false negatives, 1041 false positives in 100000 queries, rate 0.01041; theory 0.01004; estimated_fp_rate 0.01001
  20000 inserted, IX m = 95851, k = 7: 0 false negatives, 15616 false positives in 100000 queries, rate 0.15616; theory 0.15745; estimated_fp_rate 0.15898
```

A la capacidad, 1041 de los 100 000 enteros nunca insertados pasan. El intervalo predicho, tres desviaciones típicas alrededor de 0,01004, era [0,00909; 0,01098]. Al doble de la capacidad, la tasa es del 15,6 %, también dentro de su intervalo predicho. Nada avisa de que el filtro ha superado su capacidad: `insert` no devuelve nada, y `len()` cuenta las inserciones sin compararlas con nada.

[`estimated_fp_rate`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/bloom.rs#L82-L87) eleva la proporción de bits a 1 a la potencia k. Sigue la tasa medida sin saber cuántos elementos entraron, lo que la convierte en la comprobación que hay que hacer sobre un filtro que llenó otra persona. Los bits se guardan en un `Vec<bool>` ([`bloom.rs` 22](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/bloom.rs#L22)), un byte por bit. Este filtro ocupa por tanto 95 851 bytes, donde un vector compacto ocuparía 11 982, como reconoce el `CONTRACTS.md` del crate.

## 2. HyperLogLog: cuántos elementos distintos

[HyperLogLog](https://dmtcs.episciences.org/3545) guarda m = 2^p registros pequeños. El hash de cada elemento elige un registro con sus p bits bajos. En los bits restantes, la posición del primer 1 es su **rango**: el rango r aparece aproximadamente una vez de cada 2^r hashes distintos. Cada registro guarda el mayor rango que ha visto, y la estimación es una media armónica corregida de sesgo, α m² / Σ 2^(−registro). Los duplicados no cambian nada, porque un mismo elemento cae siempre en el mismo registro con el mismo rango. Por debajo de 2,5 m, cuando muchos registros siguen a cero, el estimador pasa al conteo lineal, m ln(m / ceros).

Flajolet, Fusy, Gandouet y Meunier dan un error estándar de 1,04/√m. La versión escrita a mano en `sketch.rs` implementa el mismo estimador, pero usa splitmix64 como hash: no comparte nada con el hash de IX. Con 100 conjuntos disjuntos de 100 000 enteros y p = 10:

```text
== HyperLogLog, p = 10 (1024 registers): 100 disjoint sets of 100000 integers
  predicted standard error 1.04 / sqrt(1024) = 0.0325
  IX, DefaultHasher: RMS relative error 0.0354, mean 0.0028, worst 0.1038
  hand, splitmix64 : RMS relative error 0.0340, mean 0.0076, worst 0.1016
```

Los dos errores están en el intervalo predicho, [0,0256; 0,0394]. Mil bytes estiman 100 000 elementos distintos con un error de alrededor del 3,5 % la mayor parte del tiempo, y el peor de los 100 conjuntos se desvía alrededor de un 10 %. numpy reproduce la versión escrita a mano e imprime los mismos tres números.

El error estándar es una cifra asintótica. La tabla siguiente no estaba predicha: la misma comparación con otras cardinalidades, 100 conjuntos en cada una.

```text
== HyperLogLog across cardinalities, p = 10, 100 sets each (not preregistered)
  n =    500: IX mean  0.0001, RMS 0.0225; hand mean -0.0011, RMS 0.0235
  n =   2000: IX mean  0.0020, RMS 0.0304; hand mean  0.0034, RMS 0.0289
  n =   2560: IX mean  0.0244, RMS 0.0402; hand mean  0.0234, RMS 0.0421
  n =   3000: IX mean  0.0118, RMS 0.0280; hand mean  0.0148, RMS 0.0289
  n =   4000: IX mean  0.0055, RMS 0.0257; hand mean  0.0052, RMS 0.0334
  n =   6000: IX mean  0.0031, RMS 0.0271; hand mean  0.0010, RMS 0.0321
  n =  10000: IX mean  0.0050, RMS 0.0296; hand mean  0.0026, RMS 0.0341
  n = 100000: IX mean  0.0028, RMS 0.0354; hand mean  0.0076, RMS 0.0340
  HyperLogLog::standard(): memory_bytes 16384, error_rate 0.0081
```

En n = 2560 = 2,5 m, las dos implementaciones sobrestiman entre un 2,3 y un 2,4 % de media. Con 100 conjuntos, el error estándar de una media es de unos 0,0033, así que la desviación equivale a unos siete errores estándar. Es un sesgo, no ruido. Es justo ahí donde [`count`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/hyperloglog.rs#L83-L89) deja el conteo lineal por el estimador bruto, que a ese tamaño está sesgado hacia arriba. Por eso [HyperLogLog++](https://research.google/pubs/hyperloglog-in-practice-algorithmic-engineering-of-a-state-of-the-art-cardinality-estimation-algorithm/) corrige la estimación bruta con sesgos medidos. Por debajo del cambio, el conteo lineal es más preciso que 1,04/√m.

La última línea muestra el valor por defecto: `standard()` usa p = 14 y 16 384 bytes. La primera línea del módulo promete "~1.6KB memory", algo que ninguna precisión da.

## 3. Count-min: cuántas veces

Un [count-min sketch](https://doi.org/10.1016/j.jalgor.2003.12.001) es una tabla de d filas de w contadores. Añadir un elemento incrementa un contador por fila, elegido por el hash de esa fila. Su estimación es el menor de sus d contadores. Cada contador que toca un elemento contiene su propio conteo más los de los elementos que lo comparten, así que la estimación nunca se queda corta. La cota de Cormode y Muthukrishnan explica por qué funciona el mínimo. Con w = ⌈e/ε⌉ y d = ⌈ln(1/δ)⌉, el sobreconteo supera εN con probabilidad de como mucho δ, donde N es el conteo total. En términos de la anchura, la cota es e·N/w con probabilidad 1 − e^(−d). Por la desigualdad de Markov, una fila supera e veces su sobreconteo esperado con probabilidad de como mucho 1/e, y d filas independientes lo hacen todas con probabilidad e^(−d).

El comentario de [`CountMinSketch::new`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/count_min.rs#L22-L23) omite la e: "Error <= total_count / width with probability >= 1 - (1/e)^depth". N/w es el sobreconteo *esperado* de una fila, y una fila supera su esperanza aproximadamente la mitad de las veces. La predicción era que más de e^(−3) de los elementos incumplirían la cota documentada, y menos de e^(−3) la cota real:

```text
== count-min sketch: new(100, 3), 10000 integers added 10 times each
  N = 100000; underestimates 0; mean overcount 911.3; max overcount 1180
  share above N/width = 1000: 0.0992 (binomial model 0.1058; the doc allows 0.0498)
  share above e N/width = 2718: 0.0000
  with_error(0.01, 0.05): width 272, depth 3
```

Uno de cada diez elementos se pasa en más de 1000, el doble de lo que permite el comentario. El modelo binomial detrás de la predicción trata la carga de cada fila como una Binomial(9999, 1/100) y da 0,1058. Ningún elemento se acerca a 2718. [`with_error`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/count_min.rs#L35-L39) dimensiona la tabla correctamente, con anchura ⌈e/0,01⌉ = 272 y profundidad ⌈ln 20⌉ = 3. Solo el comentario de `new` enuncia la cota errónea.

## 4. Filtros cuco: pertenencia con borrado

Un filtro de Bloom no puede olvidar un elemento, porque sus bits son compartidos. Un [filtro cuco](https://doi.org/10.1145/2674005.2674994) guarda una **huella** corta de cada elemento (16 bits en IX) en una de dos celdas de 4 huecos. La primera celda sale del hash del elemento. La segunda es la primera combinada por XOR con un hash de la huella, así que cada celda se calcula a partir de la otra y de la huella sola ([`alt_index`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/cuckoo.rs#L147-L151)). Cuando las dos celdas están llenas, la inserción desplaza una huella a su otra celda, que puede desplazar otra, hasta 500 veces. Borrar quita una copia de la huella.

```text
== cuckoo filter: new(4096), integers 0, 1, 2, ... until an insert fails
  4096 slots; first failure inserting 3730, load factor 0.9106
  earlier integers no longer found: 1 [2498]; the failed integer found: true
  false positives on 100000 integers never inserted: 14, rate 0.00014
  a second filter on the same sequence: same failure true, contains disagreements 0
```

- **Factor de carga:** el primer fallo llega al 91 % de los huecos, por encima del 0,90 predicho pero por debajo del 95 % que Fan, Andersen, Kaminsky y Mitzenmacher informan con celdas de 4.
- **Falsos positivos:** 14 de 100 000. Una consulta compara su huella con los 8 huecos de dos celdas llenas al 91 %, lo que da unos 8 × 0,91 / 65 536 ≈ 1,1 de cada 10 000.
- **La inserción fallida:** [`insert`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/cuckoo.rs#L54-L75) colocó la nueva huella en el primer desplazamiento y llevó otra de celda en celda durante 500 desplazamientos. Cuando se rinde, devuelve false y pierde la huella que todavía lleva.
  - **El resultado:** 3730, el entero "no insertado", se encuentra. 2498, que se insertó con éxito, ya no se encuentra. Es un **falso negativo**, el único error que se espera que un filtro de pertenencia no cometa.
  - **Frente al artículo:** el algoritmo 1 de Fan et al. hace lo mismo al fallar, y el artículo solo promete que no hay falsos negativos "as long as bucket overflow never occurs". La implementación de referencia de los autores guarda en cambio la huella que lleva en una caché de víctima de una entrada ([`cuckoofilter.h`](https://github.com/efficient/cuckoofilter/blob/917583d6abef692dfa8e14453bd77d6e0b61eef3/src/cuckoofilter.h#L42-L48)).
  - **Frente a la documentación de IX:** el comentario de `insert` solo dice "Returns false if the filter is full", y ni él ni `CONTRACTS.md` mencionan la pérdida.
- **Determinismo:** el `CONTRACTS.md` del crate dice que las víctimas se eligen con `rand::random()` y que las ejecuciones no son deterministas. Fan et al. sí eligen al azar una celda y una entrada. IX siempre empieza por la primera celda y elige el hueco `fingerprint % len` ([`cuckoo.rs` 60](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/cuckoo.rs#L60)), y el crate no depende de `rand`. Dos filtros alimentados con los mismos enteros fallan en el mismo y coinciden en los 100 000 sondeos.

```text
== cuckoo filter: the same integer inserted again and again
  insert(42) ten times: [true, true, true, true, true, true, true, true, false, false]; len 8
```

Un filtro cuco no sabe si un elemento ya está presente. Cada inserción guarda otra copia de la misma huella, y tras 8 copias, la capacidad de sus dos celdas, la siguiente inserción falla. Fan et al. lo advierten: los filtros cuco "are not suitable for applications that insert the same item more than 2b times". Compruebe `contains` antes de insertar cuando la entrada pueda repetirse, y no borre nunca un elemento que no se insertó: otro elemento con la misma huella en la misma celda perdería su copia.

## 5. Las predicciones, puntuadas

| | Predicción, escrita antes de la primera ejecución | Medida | Veredicto |
|---|---|---|---|
| P1 | Bloom a la capacidad: tasa en [0,00909; 0,01098] | 0,01041 | Confirmada |
| P2 | Bloom al doble de la capacidad: tasa en [0,1540; 0,1609] | 0,15616 | Confirmada |
| P3 | HyperLogLog, p = 10: error cuadrático medio en [0,0256; 0,0394], media a ±0,00975, en IX y a mano | 0,0354 y 0,0028; 0,0340 y 0,0076 | Confirmada |
| P4 | Count-min: más de 0,0498 de los elementos por encima de N/w, en [0,07; 0,20]; menos de 0,0498 por encima de e·N/w | 0,0992; 0,0000 | Confirmada |
| P5 | Cuco: primer fallo con un factor de carga de al menos 0,90 | 0,9106 | Confirmada |
| P6 | Cuco: tras el primer fallo, un elemento insertado antes ya no se encuentra | 2498 | Confirmada |
| P7 | Cuco: dos filtros alimentados con la misma secuencia se comportan igual | Mismo fallo, 0 discrepancias | Confirmada |

Las siete predicciones se cumplieron en la primera ejecución. P1 a P3 comprueban que las estructuras respetan su teoría. P4, P6 y P7 se escribieron para detectar un desacuerdo entre la documentación de IX y su código, visto antes al leerlo: las tres encontraron uno. Ninguna de las siete se ajustó después de la ejecución. El único cambio posterior es el número de conjuntos de la tabla de la sección 2, que no era una predicción, y el diario lo dice.

## Qué usar en nuestros repositorios

- **Filtro de Bloom:** dimensiónelo para el mayor conjunto que vaya a contener, porque nada avisa cuando está lleno. Lea `estimated_fp_rate()` en lugar de fiarse de la capacidad que eligió otra persona.
- **HyperLogLog:** fusione sketches de la misma precisión para contar elementos distintos entre varias fuentes: `merge` toma el máximo registro a registro. Cuente con un sesgo de unos pocos puntos porcentuales alrededor de 2,5 m, y publique la barra de error, porque 1,04/√m es una desviación típica, no un límite.
- **Count-min sketch:** dimensiónelo con `with_error`, cuya cota es correcta, y lea el comentario de `new` como erróneo por un factor e. Las estimaciones son cotas superiores: útiles para encontrar los elementos pesados, no para contar con exactitud los ligeros.
- **Filtro cuco:** trate un `insert` fallido como un filtro en el que ya no se puede confiar y reconstrúyalo más grande, porque un fallo borra en silencio otro elemento (hallazgo 26). Dimensiónelo muy por debajo del 91 % de carga, y compruebe `contains` antes de insertar entradas que puedan repetirse.

## Ejercicios

1. Un filtro de Bloom debe contener 1 000 000 de elementos con una tasa de falsos positivos del 0,1 %. ¿Cuántos bits y hashes elige `BloomFilter::new`, y cuántos bytes ocupa entonces el filtro de IX?
2. ¿Por qué un HyperLogLog ignora los duplicados, y por qué un count-min sketch no puede hacerlo?
3. En el experimento count-min, el sobreconteo medio es 911, por debajo de N/w = 1000, y sin embargo uno de cada diez elementos supera 1000. ¿Cómo pueden ser ciertas ambas cosas?
4. Proponga un cambio en `CuckooFilter::insert` para que una inserción fallida no pierda nada, y diga qué más debe mirar entonces `contains`.

<details>
<summary>Soluciones</summary>

1. m = ⌈−10⁶ ln 0,001 / (ln 2)²⌉ = 14 377 588 bits y k = ⌈(m/n) ln 2⌉ = ⌈9,97⌉ = 10 hashes. Como `Vec<bool>`, son 14 377 588 bytes, unos 14,4 MB, donde bits compactos ocuparían unos 1,8 MB.
2. HyperLogLog guarda un máximo por registro: el mismo elemento da el mismo registro y el mismo rango, así que añadirlo otra vez no puede subir el máximo. Un contador count-min es una suma: añadir otra vez el mismo elemento lo aumenta, que es lo que necesita un conteo de frecuencias.
3. Cada estimación es el mínimo de tres contadores. Ese mínimo suele estar por debajo de la media de su fila, unos 1000, lo que baja el sobreconteo medio a 911. Pero un elemento supera 1000 en cuanto sus tres contadores lo superan, lo que ocurre aproximadamente 0,47³ ≈ 0,1 de las veces con estas cargas.
4. Guardar la huella que todavía se lleva cuando se agotan los desplazamientos en un hueco "víctima" de una entrada, como hace la implementación de referencia de los autores, y devolver false solo si ese hueco ya está ocupado. `contains` y `remove` deben entonces comparar también con la víctima, y la siguiente inserción con éxito puede intentar recolocarla.

</details>

## Fuentes

- IX en el commit fijado `490c395`: [`bloom.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/bloom.rs), [`hyperloglog.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/hyperloglog.rs), [`count_min.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/count_min.rs), [`cuckoo.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/cuckoo.rs) y [`CONTRACTS.md`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/CONTRACTS.md).
- B. H. Bloom, ["Space/time trade-offs in hash coding with allowable errors"](https://doi.org/10.1145/362686.362692), *Communications of the ACM* 13, 1970.
- P. Flajolet, É. Fusy, O. Gandouet y F. Meunier, ["HyperLogLog: the analysis of a near-optimal cardinality estimation algorithm"](https://dmtcs.episciences.org/3545), *Analysis of Algorithms* (AofA 07), DMTCS Proceedings, 2007.
- S. Heule, M. Nunkesser y A. Hall, ["HyperLogLog in practice"](https://research.google/pubs/hyperloglog-in-practice-algorithmic-engineering-of-a-state-of-the-art-cardinality-estimation-algorithm/), EDBT 2013: el sesgo del estimador bruto en cardinalidades pequeñas.
- G. Cormode y S. Muthukrishnan, ["An improved data stream summary: the count-min sketch and its applications"](https://doi.org/10.1016/j.jalgor.2003.12.001), *Journal of Algorithms* 55, 2005.
- B. Fan, D. G. Andersen, M. Kaminsky y M. D. Mitzenmacher, ["Cuckoo filter: practically better than Bloom"](https://doi.org/10.1145/2674005.2674994), CoNEXT 2014 ([PDF](https://www.cs.cmu.edu/~dga/papers/cuckoo-conext2014.pdf)): algoritmos 1 a 3, 95 % de ocupación con celdas de 4 y el límite de 2b inserciones repetidas. Su implementación de referencia, [efficient/cuckoofilter](https://github.com/efficient/cuckoofilter/blob/917583d6abef692dfa8e14453bd77d6e0b61eef3/src/cuckoofilter.h), en `917583d`.
