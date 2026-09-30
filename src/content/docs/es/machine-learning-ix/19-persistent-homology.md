---
title: "19. La forma de los datos: homología persistente"
description: "Filtraciones de Rips, diagramas de persistencia y las distancias entre ellos con ix-topo de IX, luego la semilla y la exageración temprana de los dos t-SNE de ix-manifold, con ocho predicciones escritas antes de la primera ejecución: siete se cumplieron y una quedó refutada en parte. La reducción es la estándar, pero la dimensión superior no tiene cocaras y reporta 1771 cavidades en un complejo contráctil, las dos distancias emparejan los puntos por rango en lugar de buscar un emparejamiento y violan el teorema de estabilidad en 24 nubes de 50, y el t-SNE de Barnes–Hut ignora su semilla y, con bhtsne 0.5.3 fijado, devuelve un mapa sin grupos."
sidebar:
  order: 19
---

La homología persistente describe la forma de una nube de puntos por lo que aparece y desaparece cuando se unen los puntos a una escala creciente: componentes conexas, lazos, cavidades. Cada característica recibe un nacimiento y una muerte, y un *diagrama de persistencia* reúne esos pares. [Carlsson (2009)](https://doi.org/10.1090/S0273-0979-09-01249-X) la defiende como herramienta de análisis de datos. El crate fijado [`ix-topo`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo) de IX construye la filtración, calcula los diagramas y los compara con dos distancias. Otros tres crates de IX lo llaman, dos de ellos para tomar la huella de los embeddings de voicings de GA. La misma lección vuelve luego al t-SNE, que la [lección 9](../09-other-reducers/) encontró en `ix-unsupervised`, a través de la segunda implementación de IX, en [`ix-manifold`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-manifold): un `Tsne` exacto y un `BarnesHutTsne` construido sobre el crate [bhtsne](https://docs.rs/bhtsne/0.5.3/bhtsne/).

Las ocho predicciones que pone a prueba esta lección se [escribieron en el diario](../journal/#2026-09-30--lección-19-predicha-antes-de-medir) y se commitearon antes de que existiera su código. [Los resultados](../journal/#2026-09-30--lección-19-medida) las siguen. Los experimentos están en [`topology.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/topology.rs), una prueba por predicción, y [`l19_topology.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/examples/l19_topology.rs) imprime lo que miden. [`crosscheck.py`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/crosscheck/crosscheck.py) vuelve a calcular los diagramas con conjuntos de Python, las distancias exactas con [`maximum_bipartite_matching`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.sparse.csgraph.maximum_bipartite_matching.html) y [`linear_sum_assignment`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.optimize.linear_sum_assignment.html) de SciPy, y los dos emparejamientos de IX una vez más, y encuentra los mismos números.

## 1. Un círculo a una escala creciente

El complejo de Vietoris–Rips a la escala r une todo conjunto de puntos cuyas distancias dos a dos valen todas como mucho r: una arista para dos puntos, un triángulo para tres, un tetraedro para cuatro. Cuando r crece, solo se añaden símplices, así que los complejos forman una *filtración*. `rips_complex(points, max_dim, max_radius)` la construye hasta la dimensión max_dim y da a cada símplice su diámetro, la mayor distancia entre dos de sus vértices, como valor de filtración, la convención de [Ripser](https://doi.org/10.1007/s41468-021-00071-5) ([`simplex.rs` 216](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/simplex.rs#L216)). Una componente nace en 0 y muere cuando una arista la fusiona con otra más antigua. Un lazo nace con la arista que lo cierra y muere cuando unos triángulos lo rellenan. Una característica que nunca muere dentro de la filtración es *esencial*, con muerte ∞.

El círculo de la lección tiene 24 puntos en los ángulos 2πi/24 y los radios 1 + 0,1·(2u − 1), con u uniforme sacado del generador del curso:

```text
== the circle
24 points at radii 1 +- 0.1; diameter 2.1592, so every simplex is present at 2.5
```

En 2,5 el complejo es un símplice lleno sobre 24 vértices, que es contráctil: una componente, ningún lazo, ninguna cavidad.

## 2. La reducción es la estándar

`compute_persistence` reduce la matriz de borde sobre Z/2, columna por columna en el orden de filtración, y empareja la fila más baja de cada columna con ella ([`persistence.rs` 70-163](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/persistence.rs#L70-L163)): el algoritmo de [Edelsbrunner, Letscher y Zomorodian (2002)](https://doi.org/10.1007/s00454-002-2885-2) y de [Zomorodian y Carlsson (2005)](https://doi.org/10.1007/s00454-004-1146-y). Encuentra cada cara recorriendo toda la lista de símplices, lo que cuesta tiempo, no corrección, y descarta los pares cuya persistencia está por debajo de 10⁻¹⁵. La lección escribe la misma reducción con una tabla hash de caras a columnas. También comprueba H₀ frente a [Kruskal (1956)](https://doi.org/10.1090/S0002-9939-1956-0078686-7): en una filtración de Rips, una componente muere a la longitud de la arista que la fusiona, así que las muertes finitas de H₀ son las longitudes de las aristas de un árbol de expansión mínima. P1 compara las tres:

```text
== P1, compute_persistence(rips_complex(points, 2, 2.5)) against a reduction written here
  H0: 23 finite pairs, 1 essential; equal to the reduction's: yes; deaths are Kruskal's tree, bit for bit: yes
  H1 pairs: 1, equal to the reduction's: yes
  persistence above 0.5: born 0.3153 (longest gap between neighbours 0.3153), dies 1.7007
  no other H1 pair
```

Cada par coincide, bit a bit. El único lazo del círculo nace cuando el anillo se cierra, en el mayor de los 24 huecos entre vecinos, y muere en 1,7007. Para puntos equiespaciados sobre un círculo de radio 1 moriría cerca de √3 = 1,732, el lado del triángulo equilátero inscrito, donde el complejo deja de ser un círculo ([Adamaszek y Adams 2017](https://arxiv.org/abs/1503.03669)). Todos los demás pares de H₁ tienen persistencia nula y se descartaron. La comprobación cruzada encuentra el mismo lazo con conjuntos de Python y las mismas muertes de H₀ con [`minimum_spanning_tree`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.sparse.csgraph.minimum_spanning_tree.html) de SciPy.

## 3. La dimensión superior no tiene cocaras

Un lazo solo pueden rellenarlo triángulos, y una cavidad solo tetraedros. `persistence_from_points(points, max_dim, max_radius)` construye `rips_complex(points, max_dim, max_radius)` y devuelve los diagramas hasta max_dim, que su comentario de documentación describe como «maximum homology dimension (1 = loops, 2 = voids)» ([`pointcloud.rs` 30-44](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/pointcloud.rs#L30-L44)). Pero un complejo construido hasta la dimensión max_dim no tiene ningún símplice de dimensión max_dim + 1, así que nada puede matar un ciclo de la dimensión superior: cada uno de ellos se reporta como esencial. `betti_at_radius` y `betti_curve` ([`pointcloud.rs` 46-89](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/pointcloud.rs#L46-L89)) cuentan el número de Betti superior de la misma forma, a través de `betti_numbers`, donde la dimensión superior no tiene borde que restar ([`simplex.rs` 142-199](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/simplex.rs#L142-L199)). P2 pide los diagramas del círculo en 2,5, donde la respuesta es (1, 0, 0), y los de las cuatro esquinas del cuadrado unidad en 1,5, por encima de la diagonal √2:

```text
== P2, the top dimension without cofaces, the circle at max_radius 2.5
  persistence_from_points(points, 1, ..): H1 253 pairs, 253 essential   (C(24, 2) - 24 + 1 = 253)
  persistence_from_points(points, 2, ..): H1 right: yes, 0 essential; H2 1771 pairs, 1771 essential   (C(23, 3) = 1771)
  H2 from the reduction written here, up to tetrahedra: 2 pairs, 0 essential
  the unit square's corners at radius 1.5: betti_at_radius [1, 3] with max_dim 1, [1, 0, 1] with max_dim 2; up to tetrahedra [1, 0, 0]
```

Con max_dim = 1, el complejo es el grafo completo sobre 24 vértices, y cada uno de sus 253 ciclos independientes se reporta como un lazo que nunca muere. Con max_dim = 2, H₁ es correcto, pero H₂ tiene ahora 1771 cavidades esenciales, una por cada 2-ciclo independiente del 2-esqueleto lleno. Construida una dimensión más arriba, la reducción de la lección encuentra 2 pares finitos de H₂ y ninguno esencial. El cuadrado lo muestra a pequeña escala: `betti_at_radius` reporta 3 lazos con max_dim = 1 y una cavidad con max_dim = 2, donde un tetraedro lleno no tiene ninguna.

El remedio es construir una dimensión más arriba que el último diagrama que se lee. Tres llamadores en el commit fijado pasan max_dim = 1 y leen β₁: `topology` en ix-voicings, que devuelve los pares esenciales de H₁ como β₁ ([`lib.rs` 879-899](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-voicings/src/lib.rs#L879-L899)); la huella diaria de ix-embedding-diagnostics ([`main.rs` 697](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-embedding-diagnostics/src/main.rs#L697)); y la herramienta MCP `ix_topo`, por defecto ([`handlers.rs` 2151](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-agent/src/handlers.rs#L2151)). Las 14 huellas conservadas en [`state/quality-snapshots/embeddings/`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/state/quality-snapshots/embeddings), del 2026-04-12 al 2026-04-25, reportan todas β₁ = 0, y tienen razón: a su radio, los 100 puntos de cada instrumento están unidos por 2 a 6 aristas, un bosque sin ciclos. El hallazgo no cambia ninguna, pero cambiaría la primera huella cuyo grafo cierre un ciclo.

## 4. Dos distancias entre diagramas

Dos diagramas se comparan emparejando sus puntos, donde cualquier punto puede emparejarse también con la diagonal, al coste de su distancia a ella, (muerte − nacimiento)/2 en la norma L∞. La distancia bottleneck es el menor coste máximo alcanzable; la distancia de p-Wasserstein es el menor (Σ costeᵖ)^(1/p) alcanzable. Dos puntos esenciales deben emparejarse entre sí, así que diagramas con distinto número de ellos están infinitamente lejos. [Cohen-Steiner, Edelsbrunner y Harer (2007)](https://doi.org/10.1007/s00454-006-1276-5) definen la primera; [Kerber, Morozov y Nigmetov (2017)](https://doi.org/10.1145/3064175) calculan las dos exactamente. La lección las calcula por bisección sobre los costes candidatos con un emparejamiento bipartito por caminos aumentantes, y con el algoritmo húngaro de [Kuhn (1955)](https://doi.org/10.1002/nav.3800020109), y comprueba las dos frente a todas las asignaciones de problemas pequeños.

El comentario de documentación de `bottleneck_distance` da la definición: «the infimum over all matchings of the maximum cost of any matched pair». El código, cuyo comentario en línea dice «Simple approximation», completa cada diagrama con las proyecciones sobre la diagonal de los puntos del otro, ordena las dos listas por persistencia y las empareja rango por rango ([`persistence.rs` 165-213](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/persistence.rs#L165-L213)). `wasserstein_distance` descarta los puntos esenciales, completa la lista más corta con proyecciones de los puntos de la más larga, ordena las dos por *nacimiento* y las empareja índice por índice ([`persistence.rs` 215-255](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/persistence.rs#L215-L255)). Ninguna busca entre los emparejamientos. P3 construye diagramas donde eso importa:

```text
== P3, hand-made diagrams: IX, exact
  bottleneck, {(0, 2), (10, 11)} and {(10, 12), (0, 1)}: 10.0000, 1.0000
  W1, {(0, 10), (1, 2)} and {(1, 10), (0, 2)}: 16.0000, 2.0000; W2: 11.3137, 1.4142
  {(0, inf)} and an empty diagram: IX's bottleneck 0.0000, IX's W2 0.0000; exact inf
```

En el primer par, (0, 2) y (10, 12) tienen la misma persistencia, así que ordenar por persistencia los empareja, al coste 10, donde (0, 2) con (0, 1) y (10, 11) con (10, 12) cuestan 1 cada uno. En el segundo, ordenar por nacimiento pone (0, 2) frente a (0, 10) y (1, 2) frente a (1, 10), al coste 8 cada uno, donde intercambiar las parejas cuesta 1 cada una. Y un diagrama con un lazo esencial está a distancia 0 de uno vacío, cuando no existe ningún emparejamiento.

## 5. Siempre por encima, y casi siempre estrictamente

Los dos emparejamientos de IX son admisibles, así que ninguna de las dos distancias puede quedar por debajo de la exacta. P4 pregunta cuántas veces queda por encima, en 1000 pares de diagramas de 5 puntos aleatorios, cada uno nacido uniformemente en [0, 1] con una persistencia uniforme en [0, 1]:

```text
== P4, 1000 pairs of random 5-point diagrams
  bottleneck: IX at least the exact distance in 1000, above it by more than 1e-9 in 999; median of IX / exact 2.29
  W1: IX at least the exact distance in 1000, above it by more than 1e-9 in 982; median of IX / exact 1.64
```

IX nunca queda por debajo y casi siempre por encima: su distancia bottleneck es exacta en un par de 1000, y la razón mediana es 2,29. La distancia bottleneck exacta vale como mucho la mitad de la mayor persistencia, aquí 0,5, mientras que IX empareja las proyecciones sobre la diagonal en el orden de las listas. La comprobación cruzada vuelve a calcular los dos emparejamientos de IX en Python y las distancias exactas con SciPy, y cuenta los mismos 1000, 999, 1000 y 982.

## 6. El teorema de estabilidad, y lo que lo viola

Lo que hace que valga la pena comparar diagramas es la estabilidad: mover cada punto de una nube como mucho δ cambia el diámetro de cada símplice como mucho 2δ, y luego la distancia bottleneck entre los diagramas como mucho 2δ ([Cohen-Steiner et al. 2007](https://doi.org/10.1007/s00454-006-1276-5); [Chazal et al. 2009](https://doi.org/10.1111/j.1467-8659.2009.01516.x)). Un cambio pequeño en los datos no puede producir un cambio grande en el diagrama. P5 toma 50 nubes de 24 puntos uniformes en el cuadrado unidad, mueve cada punto exactamente δ = 0,01 en una dirección aleatoria y compara los diagramas de H₁, construidos hasta los triángulos para que H₁ tenga sus cocaras:

```text
== P5, stability: 50 clouds of 24 points, each point moved by 0.01, H1 from persistence_from_points(.., 2, 1.5)
  H1 pairs in a diagram: fewest 0, most 7
  exact bottleneck at most 2 delta = 0.02: 50 of 50, largest 0.0195
  IX's bottleneck above 0.02: 24 of 50, largest 0.2526
```

El teorema se cumple para la distancia exacta en 50 nubes de 50. La distancia de IX viola la cota en 24 de ellas, la peor en más de 12 veces. El emparejamiento rango por rango lo explica: cuando dos lazos de persistencias cercanas intercambian sus rangos, o un lazo más corto que 2δ aparece o desaparece y desplaza los rangos siguientes, empareja puntos que no tienen nada que ver entre sí. Quien aplique un umbral a la distancia de IX para decidir si dos embeddings tienen la misma forma mide el orden de las persistencias tanto como la forma.

## 7. El t-SNE de Barnes–Hut ignora su semilla

El t-SNE ([van der Maaten y Hinton 2008](https://jmlr.org/papers/v9/vandermaaten08a.html)) convierte las distancias en probabilidades de vecindad P, con el ancho de banda de cada fila elegido para que su entropía sea el logaritmo de la perplejidad, y luego mueve puntos en el plano hasta que sus similitudes de Student Q coinciden con P. La versión de Barnes–Hut ([van der Maaten 2014](https://jmlr.org/papers/v15/vandermaaten14a.html)) aproxima las fuerzas con un árbol. `BarnesHutTsne::with_seed` guarda una semilla, y `fit_transform` la descarta con `let _ = self.seed;`: bhtsne 0.5.3 saca su embedding inicial de `rand::thread_rng()` ([`lib.rs` 354-392](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-manifold/src/lib.rs#L354-L392); [bhtsne `tsne/mod.rs` 131-136](https://docs.rs/bhtsne/0.5.3/src/bhtsne/tsne/mod.rs.html#131-136)). El comentario encima de esa línea lo dice y prevé «Document this in the type docs», que siguen diciendo «seed 0». El `Tsne` exacto siembra un generador ChaCha8 ([`lib.rs` 131-134](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-manifold/src/lib.rs#L131-L134)). P6 ajusta 150 puntos en 10 dimensiones, tres grupos de 50 alrededor de 0, 10·e₁ y 10·e₂ con el ruido normal aproximado del curso, y puntúa cada embedding por el voto de los 5 vecinos más cercanos de cada punto en él:

```text
== P6, seeds: 150 points in three clusters in 10 dimensions
  BarnesHutTsne::with_seed(7) twice: largest coordinate difference above 1e-3: yes
  both Barnes-Hut embeddings: 5-nearest-neighbour vote right for at least 95% of the points: no; below 60%, where a random embedding gives about 1/3: yes
  Tsne::with_seed(7), 300 iterations, twice: the same embedding bit for bit: yes
```

La parte de la semilla se cumplió: dos ejecuciones de Barnes–Hut con la semilla 7 difieren, y dos ejecuciones exactas son idénticas. La otra parte quedó refutada. La predicción decía que los dos mapas de Barnes–Hut separarían los grupos; la primera ejecución obtuvo 0,267 y 0,347, cerca del tercio que da un mapa aleatorio. La prueba fija ahora esa medida, por debajo de 0,6, y mantiene el 0,95 de la predicción visible en un comentario.

La causa está en la búsqueda del ancho de banda de bhtsne 0.5.3 ([`tsne/mod.rs` 194-270](https://docs.rs/bhtsne/0.5.3/src/bhtsne/tsne/mod.rs.html#194-270)). Empieza en β = 1, donde el núcleo es exp(−β·d²). Cuando la entropía es demasiado baja, β debe bajar, y sin una cota inferior conocida todavía, el código le da el valor de una constante llamada `zero_point_five`, que vale 5,0. β sube en su lugar, la entropía baja aún más, y tras 200 pasos cada fila pone casi todo su peso en su vecino más cercano. La búsqueda solo funciona si β = 1 ya da una entropía demasiado alta, lo que exige distancias pequeñas. Aquí las distancias al cuadrado dentro de un grupo valen unos 20, y el β correcto está muy por debajo de 1. bhtsne 0.6.0 añade una prueba de regresión cuyo comentario describe exactamente esto ([`src/test.rs` 845-853](https://docs.rs/crate/bhtsne/0.6.0/source/src/test.rs)): «releases 0.5.3-0.5.4 moved beta upwards instead (a constant named `zero_point_five` was set to 5.0), making the search diverge and the conditional distribution degenerate». El espacio de trabajo de IX fija `bhtsne = "=0.5.3"` ([`Cargo.toml` 108](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/Cargo.toml#L108)). Su propia prueba de que Barnes–Hut separa dos grupos genera ruido con desviación típica 0,1, donde las distancias al cuadrado dentro de un grupo valen unos 0,16, β = 1 ya es demasiado pequeño y la búsqueda va en el sentido correcto ([`lib.rs` 548-582](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-manifold/src/lib.rs#L548-L582)). Una comprobación exploratoria, medida después de la primera ejecución, multiplica los mismos puntos por 0,3:

```text
== exploratory
  Barnes-Hut on the same points scaled by 0.3, twice: vote at least 95% in both runs: yes
```

Los mismos datos, encogidos, quedan perfectamente separados. El t-SNE debería ser invariante a esa escala, puesto que la búsqueda del ancho de banda la absorbe; este no lo es. El binario `tsne-voicings` usa Barnes–Hut por defecto, y el comentario de documentación de su enum señala que no es determinista con semilla, pero escribe `"seed": 42` en su salida ([`tsne_voicings.rs` 53-92](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-voicings/src/bin/tsne_voicings.rs#L53-L92)). No se midió si los embeddings de voicings de GA están a una escala donde la búsqueda diverge; el diario lo lista por verificar.

## 8. Una exageración temprana que nunca termina

La exageración temprana multiplica P por 12 al principio, para que los grupos se formen y se separen antes de la colocación fina. La documentación del módulo dice que `Tsne` lo hace «for the first quarter of iters» ([`lib.rs` 36-38](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-manifold/src/lib.rs#L36-L38)). El código la detiene tras `early_exaggeration_iters`, 250 por defecto, sea cual sea `n_iter` ([`lib.rs` 79](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-manifold/src/lib.rs#L79), [139-143](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-manifold/src/lib.rs#L139-L143)). Con 250 iteraciones o menos, el embedding se ajusta a 12P de principio a fin. P7 puntúa los embeddings con KL(P‖Q), frente a una P de perplejidad 30 que la lección calcula con su propia bisección:

```text
== P7, early exaggeration, the same points, seed 7, KL(P||Q) against P at perplexity 30
  200 iterations, default: the same as with_early_exaggeration(12.0, 200), bit for bit: yes
  KL after 200 iterations: default above exaggeration for the first 50: yes
```

Con 200 iteraciones, el valor por defecto es la ejecución exagerada, bit a bit, y su KL vale unas seis veces la del cuarto documentado: 1,452 frente a 0,246 en la máquina Windows del autor y en el runner Windows del CI, 1,540 frente a 0,249 en el Ubuntu del CI, 1,466 frente a 0,247 en su macOS. La misma semilla no da el mismo mapa en los tres sistemas: fija el flujo aleatorio ChaCha8, no las funciones de coma flotante que vienen después. Rust documenta la precisión de `f64::exp`, `ln` y `powi` como «non-deterministic», variable «by platform, Rust version» ([`f64::exp`](https://doc.rust-lang.org/std/primitive.f64.html#method.exp)), y la propia prueba de separación de IX bajó su umbral después de que Linux diera otras razones que Windows con la misma semilla ([`lib.rs` 485-493](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-manifold/src/lib.rs#L485-L493)). La lección no aisló qué llamada diverge primero. Por eso el ejemplo imprime la comparación, que se cumple en los tres, y no los valores: la primera ejecución del CI los imprimía, y falló en Ubuntu y macOS. Una segunda comprobación exploratoria ejecuta las 1000 iteraciones por defecto, con exageración durante las 250 primeras:

```text
  the default 1000 iterations, exaggeration for the first 250: KL within 0.05 of 200 iterations with the first 50: yes
```

Las 1000 iteraciones llegan a 0,241 en Windows, 0,237 en Ubuntu y 0,243 en macOS: 50 iteraciones exageradas de 200 quedan a unos 0,01 de las 1000 por defecto. Quien acorte `n_iter` para ahorrar tiempo, como hizo la lección, obtiene un mapa ajustado al objetivo equivocado, salvo que acorte también `early_exaggeration_iters`.

## 9. El import de la skill, y las características que quedan fuera

La página de la skill `ix-topo` muestra `use ix_topo::simplicial::{rips_complex, SimplexStream};` ([`SKILL.md` 28](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/.claude/skills/ix-topo/SKILL.md?plain=1#L28)). El crate no tiene ningún módulo `simplicial`; sus módulos son `error`, `persistence`, `pointcloud` y `simplex` ([`lib.rs` 6-9](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/lib.rs#L6-L9)). P8 conserva esa línea como doctest `compile_fail`, que falla con E0432, import no resuelto, y la misma línea con `simplex` como doctest que compila.

Una última comprobación exploratoria corta la filtración del círculo en 1,0, antes de que muera su lazo, así que el lazo es esencial ahí. `most_persistent_features` solo conserva los pares finitos ([`pointcloud.rs` 91-111](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/pointcloud.rs#L91-L111)):

```text
  the circle at max_radius 1.0: essential H1 pairs 1; most_persistent_features ranks first a pair of dimension 0, persistence 0.3057
```

La característica que clasifica primera es el último hueco que se cierra en el anillo, una componente que vive 0,31. El lazo, la única característica que un lector de este diagrama debería ver, no está en la lista en absoluto, y tampoco la componente que nunca muere.

## 10. Las predicciones, puntuadas

| | Predicción, escrita antes de la primera ejecución | Medido | Veredicto |
|---|---|---|---|
| P1 | H₀ y H₁ de IX iguales a los de una reducción escrita aquí, bit a bit; 23 muertes finitas de H₀ iguales al árbol de Kruskal; un par de H₁ por encima de 0,5, nacido en [0,25, 0,35], muerto en [1,5, 1,95] | Todo igual; nacido en 0,3153, muerto en 1,7007 | Confirmada |
| P2 | Círculo en 2,5: 253 pares esenciales de H₁ con max_dim = 1; H₁ correcto y 1771 pares esenciales de H₂ con max_dim = 2; cuadrado en 1,5: [1, 3] y [1, 0, 1] | Como se predijo; hasta los tetraedros, 2 pares finitos de H₂ y [1, 0, 0] | Confirmada |
| P3 | Bottleneck 10 frente a 1; W₁ 16 frente a 2; W₂ 11,31 frente a 1,414; un punto esencial frente a ninguno: 0 frente a ∞ | 10, 1; 16, 2; 11,3137, 1,4142; 0, 0 y ∞ | Confirmada |
| P4 | IX al menos igual a la distancia exacta en 1000 pares de 1000 para las dos, por encima en más de 10⁻⁹ en al menos 900 | 1000 y 999 para el bottleneck, 1000 y 982 para W₁ | Confirmada |
| P5 | Bottleneck exacto como mucho 0,02 en 50 nubes de 50; el de IX por encima de 0,02 en al menos 5 | 50 de 50, el mayor 0,0195; 24, el mayor 0,2526 | Confirmada |
| P6 | Dos ejecuciones de Barnes–Hut con la semilla 7 difieren en más de 10⁻³; dos ejecuciones exactas idénticas; los dos mapas de Barnes–Hut votan bien para al menos el 95 % | Distintas, idénticas; votos 0,267 y 0,347 | Refutada en parte |
| P7 | 200 iteraciones: valor por defecto igual a la exageración durante las 200, bit a bit; su KL mayor que con exageración durante las 50 primeras | Igual; 1,452 frente a 0,246 (1,540 y 0,249 en Ubuntu, 1,466 y 0,247 en macOS) | Confirmada |
| P8 | El import de la skill falla con E0432; la misma línea con `simplex` compila | Como se predijo | Confirmada |

Siete se cumplieron en la primera ejecución y una quedó refutada en parte. No se cambió ningún intervalo después. La parte refutada vino de un hueco en la lectura, no en la aritmética: la predicción leyó `ix-manifold` y se detuvo en la llamada a bhtsne, cuya búsqueda del ancho de banda dio por correcta. La prueba fija lo que midió la primera ejecución, y la comprobación de escala que lo explica está marcada como exploratoria, puesto que se eligió después de ver el resultado. Los controles muestran que las demás comprobaciones pueden fallar: la distancia exacta sí cumple la cota de estabilidad, la reducción de la lección construida una dimensión más arriba sí encuentra el H₂ correcto, y el `Tsne` exacto es reproducible en un mismo sistema.

## Qué usar en nuestros repositorios

- **`compute_persistence` y `rips_complex`:** correctas, y bit a bit la reducción estándar. La búsqueda de caras recorre toda la lista, así que mantén los complejos pequeños, o busca las caras en una tabla como hace la lección.
- **`persistence_from_points`, `betti_at_radius`, `betti_curve`:** construye una dimensión más arriba que el último diagrama o número de Betti que leas, e ignora el superior. Para β₁, pasa max_dim = 2 y lee el índice 1.
- **`bottleneck_distance` y `wasserstein_distance`:** cotas superiores, no las distancias que nombran sus comentarios de documentación, y sin la estabilidad que hace comparables los diagramas. Para un umbral o una prueba de regresión, usa un emparejamiento exacto: la bisección y el algoritmo húngaro de la lección caben en unas decenas de líneas, y `linear_sum_assignment` de SciPy lo hace en Python. Cuenta los puntos esenciales aparte; las distancias de IX los ignoran.
- **`most_persistent_features`:** añade tú mismo los pares esenciales, al principio.
- **`BarnesHutTsne`:** no reproducible, pases la semilla que pases, y con bhtsne 0.5.3 fijado su búsqueda del ancho de banda diverge salvo que las distancias a los vecinos más cercanos sean pequeñas. Pon los datos a una escala donde no diverja, comprueba el mapa con un voto de vecinos como hace la lección, o usa el `Tsne` exacto por debajo de unos miles de puntos.
- **`Tsne`:** con menos de 1000 iteraciones, fija tú mismo `early_exaggeration_iters` en un cuarto de `n_iter`. Su semilla reproduce un mapa en un mismo sistema, no entre Windows, Linux y macOS: de un sistema a otro, compara los mapas con una tolerancia o un voto de vecinos, no bit a bit.
- **La skill `ix-topo`:** importa desde `ix_topo::simplex`.

## Ejercicios

1. Demuestra que las muertes finitas de H₀ de una filtración de Rips son las longitudes de las aristas de un árbol de expansión mínima.
2. ¿Por qué el grafo completo sobre n vértices tiene C(n, 2) − n + 1 ciclos independientes, y el 2-esqueleto lleno sobre n vértices C(n − 1, 3) 2-ciclos independientes?
3. Encuentra el emparejamiento bottleneck exacto del primer par de diagramas de P3, y explica por qué ordenar por persistencia no lo encuentra.
4. ¿Por qué puede la distancia bottleneck de IX violar la cota de estabilidad, si nunca queda por debajo de la distancia exacta, que la cumple?
5. En la búsqueda de bhtsne 0.5.3, ¿qué le pasa a β cuando la entropía en β = 1 está por debajo de ln(perplejidad)? ¿Por qué ayuda multiplicar los datos por 0,3, y qué debería hacerle un cambio de escala al t-SNE?

<details>
<summary>Soluciones</summary>

1. El algoritmo de Kruskal añade las aristas por longitud creciente y conserva una arista cuando une dos componentes. En la filtración de Rips, las aristas también entran por longitud creciente, y una arista que une dos componentes es exactamente una que mata una clase de H₀, a su longitud, mientras que una arista dentro de una componente crea un lazo. Las aristas que matan son por tanto el árbol de Kruskal, con las mismas longitudes, las 23 muertes finitas de P1.
2. Un grafo conexo con V vértices y E aristas tiene E − V + 1 ciclos independientes, puesto que un árbol de expansión tiene V − 1 aristas y cada otra arista cierra un ciclo: C(n, 2) − n + 1. En el 2-esqueleto lleno, H₁ = 0, así que cada 1-ciclo es un borde y los bordes de los C(n, 3) triángulos generan un espacio de dimensión C(n, 2) − n + 1. Los 2-ciclos son el núcleo de esa aplicación: C(n, 3) − C(n, 2) + n − 1 = C(n − 1, 3). Para n = 24, 253 y 1771.
3. Empareja (0, 2) con (0, 1) al coste max(0, 1) = 1, y (10, 11) con (10, 12) al coste 1: el bottleneck vale 1. No puede ser menor, porque (0, 2) cuesta 1 frente a (0, 1), 10 frente a (10, 12) y 1 frente a la diagonal. Ordenar por persistencia empareja (0, 2) con (10, 12), ambos de persistencia 2, al coste 10, porque la persistencia no dice nada de dónde está un punto.
4. La cota restringe la distancia exacta, y la de IX solo es una cota superior de ella. Una perturbación de 0,01 puede intercambiar los rangos de dos lazos de persistencias cercanas situados en lugares distintos, o añadir un lazo de persistencia inferior a 0,02 que desplaza todos los rangos siguientes, y el emparejamiento rango por rango empareja entonces lazos lejanos. La distancia exacta emparejaría cada lazo con su copia desplazada, o un nuevo lazo diminuto con la diagonal.
5. β = 1 queda registrado como cota superior, y como no se conoce ninguna cota inferior, β pasa a 5,0 y luego se multiplica por 5 en cada paso: crece hasta que se agotan los 200 pasos, y cada fila pone casi todo su peso en su vecino más cercano. Encoger los datos por 0,3 divide cada distancia al cuadrado por unas 11, así que en β = 1 la entropía ya está por encima del objetivo y la búsqueda va en el sentido correcto. El t-SNE debería ser invariante a esa escala, puesto que los anchos de banda la absorben; el embedding no debería cambiar.

</details>

## Fuentes

- IX en el commit fijado `490c395`: [`persistence.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/persistence.rs), [`pointcloud.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/pointcloud.rs), [`simplex.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/simplex.rs), [`ix-manifold/src/lib.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-manifold/src/lib.rs), [la skill `ix-topo`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/.claude/skills/ix-topo/SKILL.md).
- bhtsne [0.5.3](https://docs.rs/bhtsne/0.5.3/bhtsne/), la versión que fija IX, y [la prueba de regresión de la 0.6.0](https://docs.rs/crate/bhtsne/0.6.0/source/src/test.rs).
- G. Carlsson, [«Topology and data»](https://doi.org/10.1090/S0273-0979-09-01249-X), Bulletin of the AMS 46, 2009.
- H. Edelsbrunner, D. Letscher y A. Zomorodian, [«Topological persistence and simplification»](https://doi.org/10.1007/s00454-002-2885-2), Discrete & Computational Geometry 28, 2002. A. Zomorodian y G. Carlsson, [«Computing persistent homology»](https://doi.org/10.1007/s00454-004-1146-y), Discrete & Computational Geometry 33, 2005.
- D. Cohen-Steiner, H. Edelsbrunner y J. Harer, [«Stability of persistence diagrams»](https://doi.org/10.1007/s00454-006-1276-5), Discrete & Computational Geometry 37, 2007. F. Chazal, D. Cohen-Steiner, L. J. Guibas, F. Mémoli y S. Y. Oudot, [«Gromov-Hausdorff stable signatures for shapes using persistence»](https://doi.org/10.1111/j.1467-8659.2009.01516.x), Computer Graphics Forum 28, 2009.
- M. Kerber, D. Morozov y A. Nigmetov, [«Geometry helps to compare persistence diagrams»](https://doi.org/10.1145/3064175), ACM Journal of Experimental Algorithmics 22, 2017.
- U. Bauer, [«Ripser: efficient computation of Vietoris–Rips persistence barcodes»](https://doi.org/10.1007/s41468-021-00071-5), Journal of Applied and Computational Topology 5, 2021.
- M. Adamaszek y H. Adams, [«The Vietoris–Rips complexes of a circle»](https://arxiv.org/abs/1503.03669), Pacific Journal of Mathematics 290, 2017.
- H. W. Kuhn, [«The Hungarian method for the assignment problem»](https://doi.org/10.1002/nav.3800020109), Naval Research Logistics Quarterly 2, 1955. J. B. Kruskal, [«On the shortest spanning subtree of a graph and the traveling salesman problem»](https://doi.org/10.1090/S0002-9939-1956-0078686-7), Proceedings of the AMS 7, 1956.
- L. van der Maaten y G. Hinton, [«Visualizing data using t-SNE»](https://jmlr.org/papers/v9/vandermaaten08a.html), JMLR 9, 2008. L. van der Maaten, [«Accelerating t-SNE using tree-based algorithms»](https://jmlr.org/papers/v15/vandermaaten14a.html), JMLR 15, 2014.
- SciPy: [`maximum_bipartite_matching`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.sparse.csgraph.maximum_bipartite_matching.html), [`linear_sum_assignment`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.optimize.linear_sum_assignment.html), [`minimum_spanning_tree`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.sparse.csgraph.minimum_spanning_tree.html).
- Rust: la precisión de [`f64::exp`](https://doc.rust-lang.org/std/primitive.f64.html#method.exp), [`ln`](https://doc.rust-lang.org/std/primitive.f64.html#method.ln) y [`powi`](https://doc.rust-lang.org/std/primitive.f64.html#method.powi).
