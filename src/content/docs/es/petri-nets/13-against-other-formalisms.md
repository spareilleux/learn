---
title: "13. Frente a otros formalismos: TLA+, statecharts, álgebras de procesos, autómatas temporizados"
description: Entregar las 25 redes del curso a TLC y comparar tres números por red, y luego preguntar qué dicen los statecharts, las álgebras de procesos y los autómatas temporizados que una red de Petri no dice.
sidebar:
  order: 13
---

La lección 11 le entregó al analizador ficheros escritos por otra herramienta. La lección 12 le entregó respuestas calculadas por otra gente. Esta lección plantea la pregunta que hay debajo de las dos: **¿es una red de Petri siquiera el lenguaje adecuado?**

Cuatro rivales cubren casi todo lo que se usa para describir la concurrencia: [TLA+](https://lamport.azurewebsites.net/tla/tla.html), los statecharts, las álgebras de procesos y los autómatas temporizados. Solo uno tiene un verificador que lee un corpus entero de redes sin un diálogo de licencia, así que solo uno se **mide** aquí. Los demás se comparan con honestidad, y se marcan como no ejecutados.

## Ejecutar el experimento

```bash
dotnet run --project code/petri-nets/Examples -c Release -- l13
```

```bash
# El contraste. tla2tools.jar no está incluido en el repositorio: descárgalo primero.
dotnet run --project code/petri-nets/Examples -c Release -- tla out/tla
java -cp tla2tools.jar tlc2.TLC -workers 1 -cleanup out/tla/mutual_exclusion.tla
```

El generador es [`Tla.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/Examples/Tla.cs), la regla de disparo que instancia es [`tla/PetriNet.tla`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/tla/PetriNet.tla), y todo el bloque de abajo está en [`expected/l13.txt`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/expected/l13.txt), comparado línea a línea por `check.sh`.

## La misma red, escrita dos veces

Una especificación TLA+ es una fórmula. Sus variables toman valores; un comportamiento es una sucesión de asignaciones. Una red de Petri es un grafo; sus plazas llevan marcas, y un marcado es una función de las plazas a los naturales. Esas dos frases se encuentran exactamente una vez: **haz que la única variable sea una función de las plazas a los naturales, y un estado TLA+ *es* un marcado.**

Así que la regla de disparo se escribe una vez, a mano, y nunca se genera:

```tla
Enabled(t) == \A p \in Places : marking[p] >= Pre[t][p]

Fire(t) ==
    /\ Enabled(t)
    /\ marking' = [p \in Places |-> marking[p] - Pre[t][p] + Post[t][p]]

Init == marking = M0
Next == \E t \in Transitions : Fire(t)
Spec == Init /\ [][Next]_marking
```

Lo que se genera es solo la red. `Nets.MutualExclusion()` se convierte en:

```tla
---------------------- MODULE mutual_exclusion ----------------------
EXTENDS Naturals

Places == {"idle1", "critical1", "idle2", "critical2", "mutex"}
Transitions == {"enter1", "leave1", "enter2", "leave2"}

PreArcs == {
    [p |-> "idle1", t |-> "enter1", w |-> 1],
    [p |-> "mutex", t |-> "enter1", w |-> 1],
    [p |-> "critical1", t |-> "leave1", w |-> 1],
    [p |-> "idle2", t |-> "enter2", w |-> 1],
    [p |-> "mutex", t |-> "enter2", w |-> 1],
    [p |-> "critical2", t |-> "leave2", w |-> 1]
}

PostArcs == {
    [p |-> "critical1", t |-> "enter1", w |-> 1],
    [p |-> "idle1", t |-> "leave1", w |-> 1],
    [p |-> "mutex", t |-> "leave1", w |-> 1],
    [p |-> "critical2", t |-> "enter2", w |-> 1],
    [p |-> "idle2", t |-> "leave2", w |-> 1],
    [p |-> "mutex", t |-> "leave2", w |-> 1]
}

M0 == [p \in Places |-> IF p \in {"idle1", "idle2", "mutex"} THEN 1 ELSE 0]
\* Every place is bounded by 1 (Invariants.PlaceBounds), so the constraint truncates nothing.
Cap == 1

VARIABLE marking
INSTANCE PetriNet
=============================================================================
```

Guardar la semántica en un módulo escrito a mano y los datos en uno generado es la diferencia entre una traducción que se puede leer y una traducción que hay que creer. El generador ocupa un centenar de líneas y no escribe ninguna lógica.

## Lo que hay que decirle al verificador

Una línea de ese módulo no está en la red en absoluto: `Cap == 1`.

TLA+ no tiene noción de acotación. Una especificación es un conjunto de comportamientos, no un grafo, y `marking[p]` recorre todo `Nat`. Dada una red no acotada, TLC enumera hasta agotar la memoria, y nunca dice *no acotada* — no dice nada, mientras se lo permitas. El `.cfg` generado lleva por eso una restricción de estado:

```
SPECIFICATION Spec
CONSTRAINT Bounded
INVARIANT TypeOK
CHECK_DEADLOCK FALSE
```

con `Bounded == \A p \in Places : marking[p] =< Cap`.

¿De dónde sale `Cap`? De [`Invariants.PlaceBounds`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Invariants.cs) — los invariantes de plaza de la lección 5. **La teoría estructural aporta el número que el verificador no sabe deducir.** Para 21 de las 25 redes los invariantes demuestran una cota y la restricción no recorta nada:

```
  21 of 25 nets carry a cap the place invariants produced.
  The other 4 have no invariant covering every place, so the generated module caps them at 3:
    unbounded-producer
    handshake
    emit-loop
    handshake-started
```

Un tope elegido a mano sería un peligro silencioso. Pon el de `queue-5` en 2 — su marcado inicial lleva cinco marcas en `room` — y TLC descarta el estado inicial antes de explorar nada:

```
Model checking completed. No error has been found.
1 states generated, 0 distinct states found, 0 states left on queue.
```

No se comprobó nada y el veredicto anuncia un éxito. No hay ninguna línea en esa salida que la distinga de una ejecución completa, y por eso el número viene de los invariantes y por eso la lección imprime qué redes recibieron un tope que no supo demostrar.

## Tres números para un espacio de estados

TLC termina con una línea del estilo `5 states generated, 3 distinct states found`, más una profundidad. Tres números. Antes de ejecutarlo sobre nada, tres apuestas:

- **estados distintos** = los marcados alcanzables del analizador;
- **estados generados** = los arcos del analizador, más uno por el estado inicial;
- **profundidad** = el más largo de los caminos más cortos del analizador, más uno, porque TLC cuenta los estados de un camino y el analizador cuenta los pasos.

Veinticinco módulos, veinticinco ejecuciones de TLC:

| red | marcados | distintos | arcos + 1 | generados | prof. + 1 | TLC |
|---|---|---|---|---|---|---|
| producer-consumer | 12 | 12 | 21 | 21 | 9 | 9 |
| handshake | 1 | 1 | 1 | 1 | 1 | 1 |
| mutual-exclusion | 3 | 3 | 5 | 5 | 2 | 2 |
| two-locks | 4 | 4 | 7 | 7 | 3 | 3 |
| two-locks-ordered | 3 | 3 | 5 | 5 | 2 | 2 |
| start-once | 3 | 3 | 4 | 4 | 3 | 3 |
| connection | 3 | 3 | 5 | 5 | 3 | 3 |
| readers-writers | 5 | 5 | 9 | 9 | 4 | 4 |
| counting-semaphore | 7 | 7 | 19 | 19 | 3 | 3 |
| philosophers-one-fork-3 | 14 | 14 | 28 | 28 | 4 | 4 |
| philosophers-ordered-3 | 12 | 12 | 23 | 23 | 4 | 4 |
| lane-lock-guarded | 7 | 7 | 15 | 15 | 4 | 4 |
| lane-lock-unguarded | 10 | 10 | 19 | 19 | 5 | 5 |
| pipeline-lifecycle | 8 | 8 | 9 | 9 | 5 | 5 |
| queue-5 | 6 | 6 | 11 | 11 | 6 | 6 |
| two-servers | 3 | 3 | 5 | 5 | 2 | 2 |
| order-sound | 6 | 6 | 8 | 8 | 5 | 5 |
| order-and-xor | 10 | 10 | 14 | 14 | 6 | 6 |
| order-xor-and | 5 | 5 | 5 | 5 | 3 | 3 |
| order-rework | 4 | 4 | 5 | 5 | 4 | 4 |
| retry | 8 | 8 | 10 | 10 | 7 | 7 |
| kanban-1 | 160 | 160 | 617 | 617 | 15 | 15 |

**Veintidós redes, sesenta y seis números, ni un desacuerdo.** Las tres redes que quedan fuera — `unbounded-producer`, `emit-loop`, `handshake-started` — no tienen grafo de alcanzabilidad finito: TLC explora el recorte que define el tope y el analizador no explora nada; también coinciden en eso, lo cual no es lo mismo que coincidir.

Las tres columnas merecen una mirada. *Estados distintos* y *marcados* coinciden porque un estado TLA+ y un marcado se hicieron el mismo objeto a propósito. *Generados* y *arcos* coinciden por otra razón, y una red estuvo a punto de romperla.

## El paso que debería haber desaparecido

En `order-sound`, dos transiciones distintas llevan de un marcado al mismo marcado: `ship` y `cancel` sacan ambas el pedido del mismo estado al mismo siguiente. Es el único par así en las 25 redes.

El grafo de alcanzabilidad de una red de Petri está **etiquetado**: son dos arcos, porque ocurrieron dos cosas distintas. La relación de transición de TLA+ no lo está: `Next` es una disyunción, y sus sucesores forman un conjunto de estados. Así que `order-sound` debería haber mostrado `arcos + 1 = 8` frente a `generados = 7`.

Muestra 8 frente a 8. TLC cuenta un estado generado **por disyunto que evalúa**, no por sucesor que conserva — la colisión se cuenta dos veces y luego se deduplica en `distinct`. La apuesta acertó por accidente, y el accidente contiene toda la diferencia entre los dos formalismos en una fila: si preguntas *qué puede pasar a continuación*, TLA+ responde con estados; si preguntas *qué puede pasar*, una red de Petri responde con transiciones. La segunda pregunta es la que necesitaba la lección 7 para hablar de inanición.

## Un marcado final no es un interbloqueo

La primera ejecución de esta lección fue errónea, y errónea de una forma que vale la pena conservar.

Con la configuración de arriba sin su última línea, TLC se detuvo tras **tres** de los ocho marcados de `retry`, y tras seis de los ocho de `pipeline-lifecycle`. No era un fallo de la traducción. TLC llama **interbloqueo** a un estado sin sucesor y se para ahí, porque una especificación TLA+ describe un sistema que sigue para siempre; tartamudear está permitido, parar no.

Una red de Petri no hace esa suposición. El marcado final de una red de flujo de trabajo es la razón de ser de la red — la lección 10 se pasa entera definiendo la solidez como *alcanzar* ese marcado. Un marcado muerto es algo que este curso calcula e informa, en `ReachabilityGraph.DeadStates`, no algo que aborte la ejecución.

`CHECK_DEADLOCK FALSE` no es, pues, una bandera de comodidad. Es el punto donde los dos formalismos no se ponen de acuerdo sobre qué *es* un sistema: un proceso reactivo, o un procedimiento que tiene un final.

## Lo que demuestra un invariante de plaza, y lo que no

Cuatro redes no tienen ningún invariante de plaza que cubra todas sus plazas, y el primer borrador de esta lección lo decía así: *las cuatro redes que los invariantes no acotan son las cuatro sin grafo de alcanzabilidad finito.*

Es falso, y la prueba lo pilló. `handshake` no tiene un invariante así y tiene **exactamente un marcado alcanzable**, porque está muerta de entrada: su `receive` deja caer una marca en `served` que nada recoge, así que ningún multiconjunto de plazas se conserva y no existe invariante alguno — y aun así nada puede crecer porque nada puede dispararse.

Un invariante de plaza es una condición **suficiente** de acotación y nunca una condición necesaria. Tres de las cuatro redes con tope son realmente no acotadas. La cuarta está acotada por una razón que los invariantes no ven.

## Lo que dice una red y no dice una especificación

```
  mutual-exclusion            3 place invariants,  3 minimal siphons,  3 minimal traps
  philosophers-one-fork-3     6 place invariants,  7 minimal siphons,  6 minimal traps
  readers-writers             2 place invariants,  2 minimal siphons,  2 minimal traps
```

Ninguno de esos nueve números necesita un estado alcanzable.

Toma la propiedad para la que existe `mutual-exclusion`: dos hilos nunca están en su sección crítica a la vez. En TLA+ se escribe como un invariante y TLC la comprueba:

```tla
AtMostOneInCritical == marking["critical1"] + marking["critical2"] =< 1
```

```
Model checking completed. No error has been found.
5 states generated, 3 distinct states found, 0 states left on queue.
```

TLC la verificó visitando los tres estados. El analizador no visita ninguno: `critical1 + critical2 + mutex = 1` es un invariante de plaza, calculado desde la matriz de incidencia por eliminación de Farkas, y la propiedad se sigue de él para **todo** marcado alcanzable, incluidos los que nadie enumeró. Con tres estados la diferencia es invisible. Con `Dekker-PT-020` — 11,5 millones de marcados y 1 216 millones de arcos, lección 12 — uno de los dos métodos sigue respondiendo y el otro agota un montículo de 8 GiB a los 158 segundos.

Ese es el resumen honesto de la comparación: un verificador de modelos decide más propiedades, y una red decide menos propiedades sin mirar nada.

:::note[Este bloque no lo produce check.sh]
Las cifras de TLC de arriba vienen de una ejecución manual del 2026-09-22: `tla2tools.jar` 2.19 de las [versiones de TLA+](https://github.com/tlaplus/tlaplus) (MIT), OpenJDK 25, un solo worker. El jar no está incluido, así que `check.sh` ejecuta `l13` sin él y el bloque de la lección se queda en las tres columnas del analizador. Los veinticinco módulos tardaron 20,1 s de reloj, la mayor parte en veinticinco arranques de JVM; la pasada del analizador sobre las mismas 25 redes, sifones y trampas incluidos, tarda 1,8 s.
:::

## Los statecharts

Los [statecharts](https://doi.org/10.1016/0167-6423(87)90035-9) añaden tres cosas a una máquina de estados: **jerarquía** (un estado contiene una máquina), **ortogonalidad** (un estado contiene varias máquinas funcionando a la vez) y **difusión** (un evento dispara todas las transiciones que lo esperan).

La ortogonalidad es la que se traduce limpiamente. Un estado Y con dos regiones es un producto de dos máquinas de estados, y un producto de dos máquinas de estados es lo que ya son dos plazas marcadas en paralelo; el número de estados se multiplica en ambos lados. `lane-lock-guarded` y `lane-lock-unguarded` tienen esa forma.

La jerarquía no se traduce. Una red de Petri no tiene contención: para salir de un estado compuesto se dibuja una transición por estado interno, y el dibujo crece donde el statechart seguía siendo pequeño. La difusión tampoco — una transición de red consume lo que consume, y nada más reacciona. Un modelo con un evento «parar todo» es un statechart; expresado como red, se convierte en un arco desde cada plaza.

Lo que una red conserva y un statechart abandona: **las marcas son un recuento de recursos**. Un estado de statechart está dentro o fuera. `counting-semaphore` tiene dos marcas en una plaza y no necesita ninguna segunda región para ello; lo mismo en un statechart son o dos regiones ortogonales o una variable entera fuera del formalismo, y ninguna de las dos te deja un invariante.

## Las álgebras de procesos

En [CCS](https://doi.org/10.1007/3-540-10235-3) o en [CSP](https://www.cs.cmu.edu/~crary/819-f09/Hoare78.pdf), la composición es la primitiva. Escribes dos procesos, los pones en paralelo, restringes los canales que comparten, y el comportamiento se *deriva* por las reglas operacionales. No hay grafo hasta que expandes uno.

Una red de Petri hace lo contrario. La estructura es la primitiva: plazas, transiciones, arcos, dibujados una vez. La composición no es un operador — se fusionan plazas, a mano, y `Nets.Philosophers(n)` es un bucle que construye arcos.

Ese canje se ve en todo lo que hace este curso. El análisis estructural necesita que la estructura exista antes de ejecutar nada: sifones, trampas, invariantes y la clasificación de libre elección de la lección 6 se leen todos sobre los arcos. En un álgebra de procesos esos objetos no tienen domicilio — los arcos son una consecuencia, no un dato. A la inversa, un álgebra de procesos compone: `P | Q` es un término, puedes razonar sobre `P` solo y reutilizar el resultado. Fusionar plazas no da ningún teorema así, y por eso exactamente la red Kanban de la lección 12 tuvo que reconstruirse entera en vez de ensamblarse con cuatro copias de una celda.

La igualdad también difiere. Dos marcados son iguales cuando son la misma función. Dos procesos son iguales cuando son **bisimilares**, que es una relación entre comportamientos y no entre estructuras. Dos redes con el mismo grafo de alcanzabilidad salvo etiquetado son bisimilares y siguen siendo dos redes distintas — con invariantes distintos, sifones distintos y veredictos distintos en la lección 6.

## Los autómatas temporizados

Un [autómata temporizado](https://doi.org/10.1016/0304-3975(94)90010-8) tiene relojes de valor real, guardas que los comparan con constantes, y puestas a cero en las transiciones. Su espacio de estados no es un grafo de estados sino un grafo de **zonas**: conjuntos de valuaciones de relojes, mantenidos finitos por una construcción por regiones. [UPPAAL](https://uppaal.org/) es la herramienta.

La lección 9 de este curso añadió tiempo a una red, y añadió la *otra* clase: una tasa estocástica en cada transición, que da una cadena de Markov de tiempo continuo y responde a «con qué frecuencia» en vez de «antes de cuándo». La clase determinista — un intervalo de Merlin `[a, b]` en una transición — no tiene detrás una cadena de Markov y necesita una construcción por clases de estados que el analizador no tiene. [TINA](https://projects.laas.fr/tina/) hace exactamente esa construcción para las redes de Petri temporales.

*Por verificar.* Nada de esta sección se ejecutó. No se construyó ningún modelo UPPAAL, no se calculó ningún grafo de clases de estados de TINA, y ninguna cifra de esta lección viene de ninguno de los dos. La afirmación de que una red de Petri temporal necesita clases de estados en vez de una cadena de Markov es la pregunta abierta del diario desde la lección 9, todavía abierta aquí.

## Dónde se detiene esta

- **Solo se comparó el espacio de estados.** TLC sabe comprobar propiedades temporales bajo equidad — `[]<>Enabled(t) => []<>t` es lo que realmente pregunta la cuestión de la inanición de la lección 7 — y ninguno de los 25 módulos declara una. El `.cfg` generado tiene una línea `INVARIANT` y ninguna línea `PROPERTY`.
- **Nada de PlusCal.** Los módulos son TLA+ en bruto porque la red *ya es* una relación de transición; una traducción a PlusCal añadiría un algoritmo que nadie escribió.
- **La traducción es de una sola dirección.** Nada aquí vuelve a leer un módulo TLA+ como una red, y la dirección difícil es la que no se ha hecho: una especificación cuyas variables no son un marcado no tiene red.
- **Tres de las cuatro redes no acotadas están recortadas, no analizadas.** La respuesta de TLC para ellas es una afirmación sobre el tope.

## Puntos clave

- Un estado TLA+ y un marcado de red de Petri son el mismo objeto en cuanto la única variable es una función de las plazas a los naturales; todo lo demás de la comparación se sigue de esa elección.
- En 22 redes con espacio de estados finito, los *estados distintos*, *estados generados* y *profundidad* de TLC igualan los marcados, los arcos + 1 y el más largo de los caminos más cortos + 1 del analizador. Sesenta y seis números, ni un desacuerdo.
- TLA+ no tiene noción de acotación. El tope que hace terminar a TLC viene de los invariantes de plaza — la teoría estructural alimenta al verificador, y no al revés.
- TLC se detiene en un estado sin sucesor y lo llama interbloqueo. El marcado final de una red de flujo de trabajo es ese estado, así que hay que desactivar la comprobación; los dos formalismos no coinciden en si los sistemas terminan.
- Un invariante de plaza demuestra la acotación y nunca la refuta: `handshake` no tiene invariante y tiene un solo marcado.
- Un verificador de modelos decide más propiedades. Una red decide menos propiedades sin enumerar nada, que es el único tipo de respuesta que sobrevive a 1 200 millones de arcos.

## Ejercicios

1. Genera `out/tla/queue_5.tla` y cambia `Cap` de 5 a 2 a mano. Ejecuta TLC. ¿Cuántos estados distintos encuentra, y qué significa ese número sobre la restricción?
2. `philosophers-one-fork-3` tiene un interbloqueo. Devuelve `CHECK_DEADLOCK TRUE` a su `.cfg`, ejecuta TLC y lee el contraejemplo que imprime. Compáralo con `ReachabilityGraph.PathTo` sobre el estado muerto. ¿Cuál es más accionable?
3. Añade `AtMostOneInCritical` a `two_locks.tla` como invariante y ejecuta TLC. Luego encuentra el invariante de plaza que hace la misma afirmación sin enumeración, con `l5`. ¿Cuál sobrevive a sustituir los dos cerrojos por diez?
4. `order-sound` es la única red cuyo grafo tiene dos pasos entre el mismo par de marcados. Construye una red donde tres transiciones lleven del marcado inicial al mismo sucesor, y predice los *estados generados* de TLC antes de ejecutarlo.

<details>
<summary>Soluciones</summary>

1. **Cero.** `queue-5` arranca con sus cinco marcas en `room`, así que el propio marcado inicial viola un tope de 2 y TLC lo descarta antes de explorar nada:

   ```
   Model checking completed. No error has been found.
   1 states generated, 0 distinct states found, 0 states left on queue.
   ```

   No comprobó nada y anuncia un éxito. Un tope de 4 hace lo mismo. Esa es la respuesta al ejercicio y la razón de que el tope de esta lección venga de los invariantes y no de un número que eligió alguien: una restricción de estado no es un análisis, y el veredicto de TLC se lee idéntico haya explorado todo el espacio de estados o nada. La bandera correspondiente del analizador, `ReachabilityGraph.IsComplete`, es falsa en vez de ausente.

2. TLC imprime el comportamiento más corto que llega al estado muerto: cada paso con el marcado entero, en orden. `PathTo` devuelve los nombres de transición y nada más. La traza de TLC es más fácil de leer; la lista de `PathTo` es más fácil de volver a meter en el modelo, y la lección 3 la usa exactamente para eso. Ninguna de las dos dice *por qué*: la razón es estructural, es el sifón `{fork1, fork2, fork3}` vaciándose, y solo `Structure.MinimalSiphons` de la lección 7 lo nombra.

3. TLC visita cuatro estados y no señala ningún error. `l5` imprime `held1 + free1 = 1` y `held2 + free2 = 1` para `two-locks`, de donde ningún hilo tiene dos cerrojos — y los invariantes se calculan sobre una matriz 4 × 4. Con diez cerrojos, el cálculo de invariantes crece como la matriz y el espacio de estados crece como 2¹⁰: la enumeración sigue siendo viable con diez, y deja de serlo en algún punto de la veintena, que es donde empieza el muro de la lección 12.

4. La red nueva tiene 1 marcado inicial y 3 arcos saliendo de él, así que el analizador anuncia 3 pasos; TLC anuncia **4 estados generados, 2 estados distintos encontrados**, porque cuenta un estado generado por disyunto evaluado y luego se queda con uno. La diferencia entre *generados* y *arcos + 1* sigue siendo nula, y la diferencia entre *generados* y *distintos* es donde fueron a parar las colisiones.

</details>

## Fuentes

- Leslie Lamport, *Specifying Systems*, Addison-Wesley 2002, disponible desde la [página de TLA+](https://lamport.azurewebsites.net/tla/book.html). La forma `[][Next]_v` y el sentido de una restricción de estado son los capítulos 2 y 14.
- [Las herramientas TLA+](https://github.com/tlaplus/tlaplus) (MIT). `tla2tools.jar` 2.19 es lo que produjo cada cifra de TLC de arriba; no está incluido aquí.
- David Harel, *Statecharts: A visual formalism for complex systems*, **Science of Computer Programming** 8(3), 1987, páginas 231–274, [doi:10.1016/0167-6423(87)90035-9](https://doi.org/10.1016/0167-6423(87)90035-9). El registro está confirmado por Crossref; el artículo está tras un muro de pago y no lo he leído, así que nada de lo anterior descansa solo en él — jerarquía, ortogonalidad y difusión son los tres rasgos en que coinciden todas las descripciones posteriores. *Por verificar.*
- Robin Milner, *A Calculus of Communicating Systems*, **LNCS 92**, Springer 1980, [doi:10.1007/3-540-10235-3](https://doi.org/10.1007/3-540-10235-3). Misma reserva. *Por verificar.*
- C. A. R. Hoare, *Communicating Sequential Processes*, **Communications of the ACM** 21(8), 1978, [copia del autor](https://www.cs.cmu.edu/~crary/819-f09/Hoare78.pdf). Este se lee entero y es la fuente de la afirmación de que la composición es la primitiva.
- Rajeev Alur y David Dill, *A theory of timed automata*, **Theoretical Computer Science** 126(2), 1994, [doi:10.1016/0304-3975(94)90010-8](https://doi.org/10.1016/0304-3975(94)90010-8), [copia de los autores](https://www.cis.upenn.edu/~alur/TCS94.pdf). Relojes, guardas, puestas a cero y construcción por regiones.
- [UPPAAL](https://uppaal.org/) y [TINA](https://projects.laas.fr/tina/), las dos herramientas nombradas en la sección temporizada. Ninguna se ejecutó.
- Tadao Murata, *Petri nets: Properties, analysis and applications*, **Proceedings of the IEEE** 77(4), 1989, [doi:10.1109/5.24143](https://doi.org/10.1109/5.24143), por la regla de disparo que enuncia el módulo TLA+.
