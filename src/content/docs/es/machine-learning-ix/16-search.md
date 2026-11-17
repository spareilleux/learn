---
title: "16. Búsqueda: A*, búsqueda en árbol de Monte-Carlo, búsqueda local"
description: "A* y sus variantes ponderada, bidireccional y Q*, la búsqueda en árbol de Monte-Carlo y la búsqueda local frente a ix-search de IX, con ocho predicciones escritas antes de la primera ejecución, todas cumplidas. A* ponderado mantiene su cota y el ascenso de colinas coincide con Russell y Norvig en las 8 reinas; el A* de IX necesita una heurística consistente donde su contrato dice admisible, su búsqueda bidireccional sigue los arcos directos desde la meta, su Q* no distingue un callejón sin salida del buen camino, y su MCTS juega al adversario como un compañero."
sidebar:
  order: 16
---

Buscar, para un programa, es elegir entre muchas secuencias de jugadas: una ruta en un grafo, una jugada en una partida, la configuración con mejor puntuación. El crate [`ix-search`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search) fijado de IX tiene A\* y sus variantes ponderada, bidireccional y Q\*, la búsqueda en anchura y en profundidad, minimax y alfa-beta, la búsqueda en árbol de Monte-Carlo y la búsqueda local. [`ix-graph`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-graph) tiene el algoritmo de Dijkstra. Esta lección los ejecuta sobre grafos pequeños recorridos a mano, sobre laberintos aleatorios, sobre un juego de dos jugadas y sobre las 8 reinas, y comprueba lo que promete el [`CONTRACTS.md`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/CONTRACTS.md) de IX.

Las ocho predicciones que prueba esta lección se [escribieron en el diario](../journal/#2026-09-30--lección-16-predicha-antes-de-medir) y se registraron en un commit antes de que existiera su código. [Los resultados](../journal/#2026-09-30--lección-16-medida) las siguen. Los experimentos están en [`search.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/search.rs), un test por predicción. [`l16_search.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/examples/l16_search.rs) imprime lo que miden. [`crosscheck.py`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/crosscheck/crosscheck.py) reconstruye los mismos laberintos y tableros a partir del `Rng` del curso. Resuelve los laberintos con [`csgraph.shortest_path`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.sparse.csgraph.shortest_path.html) de SciPy y repite el ascenso de colinas sobre los tableros en Python puro.

## 1. A\* y la heurística en la que confía

El A\* de [Hart, Nilsson y Raphael (1968)](https://doi.org/10.1109/TSSC.1968.300136) expande, entre los nodos que ha alcanzado, el de menor f(n) = g(n) + h(n). Aquí g(n) es el coste del mejor camino encontrado hasta ahora desde el inicio, y h(n) estima el coste que falta hasta la meta. Una heurística es *admisible* cuando nunca sobrestima, h(n) ≤ h\*(n). Es *consistente* cuando nunca baja más que el coste de un arco, h(n) ≤ c(n, n′) + h(n′). Con h = 0, A\* es el algoritmo de Dijkstra: el `uniform_cost_search` de IX es exactamente `astar` con h = 0.

El `astar` de IX mantiene un conjunto cerrado y nunca reabre un estado cerrado ([`astar.rs` 137-148](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/astar.rs#L137-L148)). Su comentario saca la consecuencia: la optimalidad «requires a **consistent** (monotone) heuristic, not merely an admissible one» ([`astar.rs` 71-74](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/astar.rs#L71-L74)). [`CONTRACTS.md` 9](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/CONTRACTS.md#L9) dice admisible. P1 lo decide con cuatro nodos. El óptimo es 5, por S, A, C, G. La heurística h(A) = 4, 0 en el resto, es admisible: desde A el camino más barato cuesta 1 + 3 = 4. No es consistente: h(A) = 4 supera c(A, C) + h(C) = 1.

```text
== A*, S→A 1, S→C 3, A→C 1, C→G 3
  h(A) = 4, 0 elsewhere  cost 6, path S C G, 3 expansions
  h = 0                  cost 5, path S A C G, 3 expansions
  h = h*                 cost 5, path S A C G, 3 expansions
  ix-graph Dijkstra       5
```

S se expande primero. A entra en la frontera con f = 1 + 4 = 5, y C con f = 3 + 0 = 3. C sale antes y se cierra con g = 3. Cuando sale A, su camino hacia C cuesta 2, pero C está cerrado y el camino más barato se salta, así que la búsqueda termina en 6. Con h = 0 o h = h\*, ambas consistentes, A\* encuentra 5, y el [`Graph::dijkstra`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-graph/src/graph.rs#L91-L125) de ix-graph también. Ese Dijkstra no tiene conjunto cerrado: vuelve a apilar un nodo cada vez que su distancia baja, y salta las entradas obsoletas. El comentario tiene razón y el contrato se equivoca. El remedio es una heurística consistente, o reabrir un estado cerrado cuando aparece un camino más barato hacia él.

## 2. A\* ponderado en laberintos

El A\* ponderado de [Pohl (1970)](https://doi.org/10.1016/0004-3702(70)90007-X) ordena la frontera por g + w·h con w > 1. Confía más en la heurística, expande menos nodos, y a cambio el camino que encuentra puede costar hasta w veces el óptimo. [`CONTRACTS.md` 10](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/CONTRACTS.md#L10) promete esa cota. Sin reapertura, necesita una heurística consistente. [Chen y Sturtevant (2021)](https://doi.org/10.1609/aaai.v35i5.16485) muestran que la consistencia es necesaria para una búsqueda best-first acotada que nunca reabre. La distancia de Manhattan en una cuadrícula con movimientos de coste 1 es consistente, así que P2 espera que la cota se mantenga. La prueba usa 100 laberintos de 30 × 30, cada casilla un muro con probabilidad 0,25, de una esquina a la otra:

```text
== 100 mazes of 30 x 30, walls with probability 0.25, Manhattan h
  far corner reachable:                84
  astar None exactly when unreachable: true
  astar cost = Dijkstra's everywhere:  true
  total optimal cost:                  5046
  A*:          mean expansions 383.7
  w = 1.5      mean expansions 145.3, over the bound 0, worst cost / optimum 1.1724
  w = 2        mean expansions 140.3, over the bound 0, worst cost / optimum 1.1724
  w = 5        mean expansions 132.6, over the bound 0, worst cost / optimum 1.4138
```

En 16 laberintos, los muros aíslan la esquina opuesta. `astar` devuelve `None` exactamente en esos 16, como dice [`CONTRACTS.md` 8](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/CONTRACTS.md#L8). En los otros 84 encuentra el coste de Dijkstra. La comprobación cruzada encuentra los mismos 84 laberintos y el mismo total de 5046 movimientos con SciPy. Ningún camino ponderado supera su cota. El peor cuesta un 17 % más que el óptimo con w = 1,5 y 2, y un 41 % con w = 5. Casi todo el ahorro llega con el primer paso por encima de 1: w = 1,5 ya expande 2,6 veces menos nodos que A\*. P2 no decía nada de w = 5 frente a w = 2. [Wilt y Ruml (2012)](https://www.cs.unh.edu/~ruml/papers/wted-astar-socs-12.pdf) muestran dominios donde un peso mayor expande más nodos. En estos laberintos expande algunos menos.

En una cuadrícula abierta, muchos nodos comparten el mismo f. [`CONTRACTS.md` 29](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/CONTRACTS.md#L29) advierte que esos empates siguen el orden interno de [`BinaryHeap`](https://doc.rust-lang.org/std/collections/struct.BinaryHeap.html). Los costes de arriba no dependen de ello, pero los números de expansiones sí.

## 3. A\* bidireccional

Una búsqueda bidireccional lanza una búsqueda hacia delante desde el inicio y otra hacia atrás desde la meta, y se detiene cuando sus fronteras ya no pueden mejorar el mejor punto de encuentro. La búsqueda hacia atrás debe seguir los arcos al revés, de cada nodo a sus predecesores. El comentario de `bidirectional_astar` lo dice: «Requires a `reverse_successors` function (predecessors from goal side)». Pero su firma no recibe ninguna función así, y la búsqueda hacia atrás llama a `successors()` ([`astar.rs` 255-264 y 357](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/astar.rs#L255-L357)). Eso solo es correcto cuando cada arco puede recorrerse al revés con el mismo coste. P3 prueba un ciclo dirigido y un camino no dirigido:

```text
== bidirectional_astar, h = 0
  directed cycle S→A→G→S: bidirectional cost 1, path S G; astar cost 2, path S A G
  path 0-1-2-3-4: bidirectional path [0, 1, 2, 3, 4], cost 4
    bidirectional actions (0, 1) (1, 2) (3, 2) (4, 3)
    astar actions         (0, 1) (1, 2) (2, 3) (3, 4)
```

En el ciclo, la búsqueda hacia atrás sale de G por G→S, que es un arco directo, y llega a S con coste 1. Las dos búsquedas se encuentran en S, y el resultado es un camino S, G de coste 1 por un arco que no existe. La respuesta correcta es 2. En el camino no dirigido, el coste y los estados son correctos, pero las acciones tras el punto de encuentro son las de la búsqueda hacia atrás: (3, 2) donde el camino va de 2 a 3. [`CONTRACTS.md` 11](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/CONTRACTS.md#L11) dice que en los caminos que devuelven `astar` y `weighted_astar`, `actions[i]` va de `path[i]` a `path[i+1]`. `bidirectional_astar` devuelve el mismo `SearchResult` y no documenta ningún otro sentido, pero añade las acciones de la búsqueda hacia atrás tal cual ([`astar.rs` 396-402](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/astar.rs#L396-L402)). Un detalle más, leído en el código y no medido aquí: cada nodo que apilan las dos búsquedas recibe f = g + h(padre), la heurística del nodo del que viene, no la suya ([`astar.rs` 334 y 366](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/astar.rs#L334-L366)). Con h = 0 no cambia nada.

## 4. Q\*: una heurística para todos los hijos a la vez

Cuando un estado tiene muchos sucesores, A\* dedica su tiempo a generarlos y a llamar a h con cada uno. El Q\* de [Agostinelli et al.](https://arxiv.org/abs/2102.04518) usa una red que recibe un estado y devuelve, en una sola llamada, el coste restante de cada transición que sale de él. Q\* puede así apilar los hijos sin generarlos. La cabecera del módulo de IX afirma que Q\* reduce «node expansions by orders of magnitude compared to A\*» ([`qstar.rs` 1-4](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/qstar.rs#L1-L4)). Pero su `QFunction` asocia un solo número a un estado. `qstar_search` la llama una vez por nodo expandido y da a cada hijo max(h(padre) − c, 0) ([`qstar.rs` 164-191](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/qstar.rs#L164-L191)). Para un hijo alcanzado con coste c ≤ h(padre), su f pasa a ser el g + h del padre, sea cual sea el hijo. P4 construye un inicio con una rama buena y 100 callejones sin salida, cuyo h de 100 dice exactamente eso:

```text
== S→A→G and 100 dead ends S→D→X: (cost, expansions, heuristic calls)
  astar           2, 2, 103
  qstar_search    2, 102, 103
  qstar_two_head  2, 2, 103
```

A\* lee h = 100 en cada callejón, lo apila con f = 101 y nunca lo expande. Q\* apila A y los 100 callejones con el mismo f = 1, por debajo del f = 2 de la meta, y tiene que expandirlos todos antes de llegar a la meta. `qstar_two_head` llama a h en cada sucesor, como A\*, y expande 2 nodos. Aquí ni siquiera ahorra llamadas a la heurística. A\* llama a h una vez por hijo que apila, Q\* una vez por nodo que expande, y Q\* expande 102 nodos para llegar a la meta. Sin una función que puntúe los hijos de un estado en una sola llamada, el Q\* de una cabeza de IX es un A\* peor informado. Otra discrepancia, también leída y no medida: el comentario de `qstar_bounded` describe una búsqueda focal con listas OPEN y FOCAL, y la función llama a `qstar_weighted` ([`qstar.rs` 292-303](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/qstar.rs#L292-L303)).

## 5. Búsqueda en árbol de Monte-Carlo

La búsqueda en árbol de Monte-Carlo construye un árbol de juego camino a camino. Cada iteración baja desde la raíz con UCB1, la regla de bandidos de la [lección 14](../14-reinforcement-learning/), que [Kocsis y Szepesvári (2006)](https://doi.org/10.1007/11871842_29) aplicaron a los árboles con el nombre de UCT. Añade un hijo no probado, termina la partida con jugadas al azar y suma el resultado a cada nodo del camino. En un juego de dos jugadores, cada nodo debe puntuarse para el jugador que lo elige. Si no, las elecciones del adversario maximizan el resultado del jugador equivocado. La revisión de [Browne et al. (2012)](https://doi.org/10.1109/TCIAIG.2012.2186810) retropropaga cada recompensa desde el punto de vista del jugador que entró en el nodo. IX suma la misma recompensa a cada nodo ([`mcts.rs` 93-99](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/mcts.rs#L93-L99)), y `MctsState::reward` vale 1 para «win» sin decir de quién ([`mcts.rs` 16-17](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/mcts.rs#L16-L17)). P5 ofrece al jugador raíz un empate seguro B, o una apuesta A donde el adversario elige después la victoria o la derrota del jugador raíz:

```text
== A (the opponent picks win or loss) or B (a draw), 2000 iterations, exploration 1.41, 20 seeds
  ix mcts_search chooses A:  20 of 20
  negamax MCTS chooses B:    20 of 20
  ix minimax:                B, value 0
```

En el árbol de IX, el nodo del adversario elige el hijo con mayor recompensa, que es la victoria del jugador raíz. A parece valer casi 1, e IX apuesta con cada semilla. El propio [`minimax`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/adversarial.rs#L32-L88) de IX elige el empate. También `negamax_mcts` de `search.rs`, que es el bucle de IX con un solo cambio: el total de cada nodo es la recompensa r cuando el jugador raíz entró en él, y 1 − r cuando entró el adversario. El `mcts_search` de IX sirve para problemas de un jugador, rompecabezas y planificación, donde cada elección es del que busca. El propio test de IX juega un Nim de dos jugadores y solo comprueba que la jugada sea legal.

Cuando dos hijos tienen el mismo número de visitas, [`CONTRACTS.md` 14](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/CONTRACTS.md#L14) dice que gana el primero encontrado. [`max_by_key`](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.max_by_key) devuelve el último máximo ([`mcts.rs` 102-107](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/mcts.rs#L102-L107)), como `max_by` en los bandidos de la lección 14. P6 da a la raíz tres jugadas hacia un empate y tres iteraciones, para que cada hijo se visite una vez. Un registro en `apply` guarda el orden de expansión:

```text
== 3 moves to a draw, 3 iterations, 20 seeds
  mcts_search returns the last expanded child 20 times, the first 0 times
```

## 6. Búsqueda local

La búsqueda local no construye caminos. Pasa de un estado a un vecino mejor, y solo importa dónde termina. El `hill_climbing` de IX pasa al mejor vecino mientras mejore. `random_restart_hill_climbing` lo repite desde nuevos inicios, `beam_search` conserva en cada paso los k mejores vecinos de todo el haz, y `tabu_search` prohíbe los estados visitados hace poco y conserva el mejor visto. [`CONTRACTS.md` 16](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/CONTRACTS.md#L16) dice que `local::hill_climb` devuelve el mejor estado visto. El crate no tiene `hill_climb`, y la única búsqueda que puede terminar por debajo de su mejor es `beam_search`. Sustituye el haz por los mejores vecinos aunque sean peores, y devuelve el mejor del último haz ([`local.rs` 97-124](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/local.rs#L97-L124)). P7 lanza cada búsqueda en la cima de f(x) = −(x − 10)²:

```text
== local search on -(x - 10)^2 from x = 10
  beam_search, beam 1,   1 steps: x = 11, value -1
  beam_search, beam 1,   2 steps: x = 10, value 0
  beam_search, beam 1, 101 steps: x = 11, value -1
  hill_climbing: x = 10, value 0; tabu_search: x = 10, value 0
  random_restart_hill_climbing from 3, 0 restarts: x = 3, value -inf, 1 generator calls
  random_restart_hill_climbing from 3, 5 restarts: x = 10, value 0, 6 generator calls
```

Un haz de 1 abandona el óptimo en el primer paso y vuelve en el segundo, así que un número impar de pasos devuelve un estado peor que el inicial. El ascenso de colinas y la búsqueda tabú conservan el óptimo. `random_restart_hill_climbing` genera un estado antes de su bucle y lo puntúa −∞ ([`local.rs` 72-95](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/local.rs#L72-L95)). Con 0 reinicios devuelve ese estado con valor −∞. Con 5, llama 6 veces al generador y descarta el primer estado.

Las 8 reinas son la prueba clásica del ascenso de colinas. El tablero tiene una reina por columna, un vecino mueve una reina dentro de su columna (56 vecinos), y h cuenta los pares de reinas que se atacan. [Russell y Norvig](https://aima.cs.berkeley.edu/) (sección 4.1.1) informan de que el ascenso más empinado desde un tablero aleatorio «gets stuck 86% of the time, solving only 14% of problem instances», «taking just 4 steps on average when it succeeds and 3 when it gets stuck». El `hill_climbing` de IX es ese algoritmo, salvo que los empates van al último mejor vecino en lugar de a uno al azar (P8):

```text
== 8 queens, IX's hill_climbing
  1000 random boards: solved 144 (14.4%), mean steps 4.08 when solved, 3.10 when stuck
  random_restart_hill_climbing, 20 restarts: solved 94 of 100 runs
```

IX cae en los números del libro. Con una tasa de éxito p = 0,144 por inicio, 20 inicios independientes tienen éxito al menos una vez con probabilidad 1 − 0,856²⁰ = 0,955, y lo tuvieron 94 ejecuciones de 100. La comprobación cruzada repite los mismos tableros en Python, con el mismo desempate. Encuentra los mismos 144 tableros resueltos, las mismas medias de pasos y las mismas 94 ejecuciones.

## 7. Las predicciones, puntuadas

| | Predicción, escrita antes de la primera ejecución | Medido | Veredicto |
|---|---|---|---|
| P1 | h(A) = 4 (admisible, no consistente): `astar` devuelve 6 por S, C, G tras 3 expansiones; h = 0, h = h\* y Dijkstra dan 5 | Como se predijo | Confirmada |
| P2 | 100 laberintos: `astar` es `None` exactamente donde Dijkstra no encuentra camino, y si no el mismo coste; w = 1,5, 2, 5 quedan dentro de w veces el óptimo; w = 2 expande menos de 0,7 veces A\* | 84 alcanzables, todos iguales; 0 por encima de la cota; 140,3 frente a 383,7 | Confirmada |
| P3 | Ciclo dirigido: coste 1 y camino [S, G], donde A\* da 2; camino 0–4: acciones (0, 1), (1, 2), (3, 2), (4, 3) | Como se predijo | Confirmada |
| P4 | 100 callejones: A\* expande 2 nodos, `qstar_search` 102, `qstar_two_head` 2, todos con coste 2, y Q\* hace 103 llamadas a la heurística como A\* | Como se predijo | Confirmada |
| P5 | `mcts_search` elige la apuesta con 20 semillas de 20; `minimax` y un MCTS negamax eligen el empate | 20 de 20; B con valor 0; 20 de 20 | Confirmada |
| P6 | Un empate va al último hijo expandido con 20 semillas de 20, al primero con ninguna | 20 y 0 | Confirmada |
| P7 | `beam_search` desde el óptimo: 11 tras 1 paso, 10 tras 2, 11 tras 101; el ascenso y el tabú se quedan en 10; 0 reinicios dan −∞, 5 reinicios llaman 6 veces al generador | Como se predijo | Confirmada |
| P8 | 8 reinas: 10 a 18 % resueltos, 3 a 5 pasos con éxito, 2 a 4 cuando se atasca; 20 reinicios resuelven entre 85 y 100 de 100 | 14,4 %, 4,08, 3,10; 94 | Confirmada |

Las ocho se cumplieron en la primera ejecución, y el código compiló a la primera. Ningún intervalo se cambió después. P1, P3, P4, P6 y P7 vienen de leer el código de IX frente a sus contratos y comentarios, y de recorrerlo a mano. P2 y P8 vienen de resultados publicados, e IX coincidió con ellos. P5 viene de la regla del libro para los árboles de dos jugadores. Los controles muestran que cada comprobación puede fallar. Una heurística consistente sí encuentra 5. `astar` sí encuentra el coste real en el ciclo. A\* y el Q\* de dos cabezas sí saltan los callejones. Minimax y el MCTS negamax sí eligen el empate. El ascenso de colinas y la búsqueda tabú sí conservan el óptimo.

## Qué usar en nuestros repositorios

- **El `astar` de IX:** dale una heurística consistente. La distancia de Manhattan en una cuadrícula y la distancia en línea recta en un mapa lo son. Una heurística admisible pero no consistente puede devolver un camino más largo.
- **El `weighted_astar` de IX:** w = 1,5 ya expandió 2,6 veces menos nodos en estos laberintos, con cada coste dentro de su cota.
- **El `bidirectional_astar` de IX:** solo en grafos donde cada arco puede recorrerse al revés con el mismo coste. Lee `path`, no `actions`, tras el punto de encuentro.
- **El `qstar_search` de IX:** no como un A\* más rápido. Con una heurística que ve un estado cada vez, usa `astar`.
- **El `mcts_search` de IX:** solo problemas de un jugador. Para un juego de dos jugadores, usa `minimax` o `alpha_beta`, o un MCTS que puntúe cada nodo para su jugador.
- **El `beam_search` de IX:** guarda tú mismo el mejor estado visto. Llama a `random_restart_hill_climbing` con al menos un reinicio.
- **El `hill_climbing` de IX:** se comporta como dice el libro. Añade reinicios: con 20, 94 ejecuciones de 100 resolvieron las 8 reinas.

## Ejercicios

1. Demuestra que una heurística consistente con h(meta) = 0 es admisible. Comprueba que la heurística de P1 es admisible pero no consistente.
2. Con una heurística consistente, demuestra que f nunca decrece a lo largo de un camino. Deduce que cuando A\* cierra un nodo su g ya es óptimo, así que no hace falta reabrir.
3. En el `qstar_search` de IX, demuestra que un hijo alcanzado con coste c ≤ h(padre) recibe f = g(padre) + h(padre). ¿Por qué Q\* no puede apartar los callejones de P4?
4. El ascenso de colinas resuelve un tablero aleatorio con probabilidad p = 0,144. ¿Cuántos inicios independientes dan al menos un 95 % de probabilidad de un éxito?

<details>
<summary>Soluciones</summary>

1. Toma un camino óptimo n = n₀, n₁, …, n_k = meta. La consistencia da h(n₀) ≤ c(n₀, n₁) + h(n₁) ≤ c(n₀, n₁) + c(n₁, n₂) + h(n₂) ≤ … ≤ el coste del camino + h(meta) = h\*(n). Para P1: h\*(A) = 1 + 3 = 4, así que h(A) = 4 es admisible, y los demás valores son 0. En el arco A→C, h(A) = 4 supera c(A, C) + h(C) = 1 + 0, así que no es consistente.
2. Para un arco n → n′, f(n′) = g(n) + c(n, n′) + h(n′) ≥ g(n) + h(n) = f(n), por consistencia, así que f nunca decrece a lo largo de un camino. Supón ahora que cada nodo cerrado hasta ahora tenía su g óptimo, y que A\* va a cerrar n con un g(n) mayor que su óptimo g\*(n). En un camino óptimo hacia n, toma el primer nodo m que no esté cerrado. Su predecesor en ese camino está cerrado con su g óptimo, así que m se apiló con g(m) = g\*(m). Si m fuera n, n ya tendría su g óptimo, así que m va antes que n en el camino. Como f no decrece a lo largo del camino óptimo, f(m) = g\*(m) + h(m) ≤ g\*(n) + h(n) < g(n) + h(n) = f(n). A\* habría tomado m primero: contradicción.
3. El hijo recibe g(padre) + c + max(h(padre) − c, 0), es decir g(padre) + h(padre) cuando c ≤ h(padre). En P4, A y cada D_i tienen f = g(S) + h(S) = 0 + 1 = 1. Sus propios valores, 1 y 100, solo se leen cuando se expanden, después de haber sido elegidos. La meta, alcanzada desde A, recibe f = 2, así que los 101 nodos con f = 1 pasan todos antes.
4. La probabilidad de que fallen los n inicios es (1 − p)ⁿ, así que n debe cumplir 0,856ⁿ ≤ 0,05, es decir n ≥ ln 0,05 / ln 0,856 = −2,996 / −0,1555 = 19,3. Veinte inicios dan 1 − 0,856²⁰ = 0,955, y la medida resolvió 94 ejecuciones de 100.

</details>

## Fuentes

- IX en el commit fijado `490c395`: [`astar.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/astar.rs), [`qstar.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/qstar.rs), [`mcts.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/mcts.rs), [`local.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/local.rs), [`adversarial.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/adversarial.rs), [`CONTRACTS.md`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/CONTRACTS.md), y el [`graph.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-graph/src/graph.rs) de ix-graph.
- P. E. Hart, N. J. Nilsson y B. Raphael, [«A formal basis for the heuristic determination of minimum cost paths»](https://doi.org/10.1109/TSSC.1968.300136), IEEE Transactions on Systems Science and Cybernetics 4, 1968.
- I. Pohl, [«Heuristic search viewed as path finding in a graph»](https://doi.org/10.1016/0004-3702(70)90007-X), Artificial Intelligence 1, 1970.
- J. Chen y N. R. Sturtevant, [«Necessary and sufficient conditions for avoiding reopenings in best first suboptimal search with general bounding functions»](https://doi.org/10.1609/aaai.v35i5.16485), AAAI 35, 2021.
- C. Wilt y W. Ruml, [«When does weighted A\* fail?»](https://www.cs.unh.edu/~ruml/papers/wted-astar-socs-12.pdf), SoCS 2012.
- F. Agostinelli et al., [«A\* search without expansions: learning heuristic functions with deep Q-networks»](https://arxiv.org/abs/2102.04518), arXiv:2102.04518.
- L. Kocsis y C. Szepesvári, [«Bandit based Monte-Carlo planning»](https://doi.org/10.1007/11871842_29), ECML 2006.
- C. B. Browne et al., [«A survey of Monte Carlo tree search methods»](https://doi.org/10.1109/TCIAIG.2012.2186810), IEEE Transactions on Computational Intelligence and AI in Games 4, 2012.
- S. Russell y P. Norvig, [*Artificial Intelligence: A Modern Approach*](https://aima.cs.berkeley.edu/), sección 4.1.1, búsqueda local en las 8 reinas.
- SciPy: [`sparse.csgraph.shortest_path`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.sparse.csgraph.shortest_path.html). Rust: [`Iterator::max_by_key`](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.max_by_key), [`BinaryHeap`](https://doc.rust-lang.org/std/collections/struct.BinaryHeap.html).
