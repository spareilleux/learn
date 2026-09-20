---
title: 5. Invariantes
description: Invariantes de plazas y de transiciones calculados por eliminación de Farkas — un recuento ponderado de marcas que ningún disparo puede cambiar, la prueba de que el búfer acotado no puede desbordarse sin enumerar ni un solo marcado, y una lista honesta de lo que un invariante no puede decidir.
sidebar:
  order: 5
---

Código completo: [`code/petri-nets`](https://github.com/spareilleux/learn/tree/main/code/petri-nets). Esta lección la imprime `dotnet run --project Examples -c Release -- l5`, y se compara con [`expected/l5.txt`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/expected/l5.txt).

Las lecciones 3 y 4 respondían a todas las preguntas por enumeración: construir el grafo de alcanzabilidad, mirar los doce marcados, informar. Eso funciona hasta que deja de funcionar — la red de la lección 3 sin su freno tiene infinitos marcados, y una red con diez filósofos tiene más de los que quieres tener en memoria.

Esta lección cambia la pregunta. En lugar de visitar los marcados y comprobar una propiedad en cada uno, mira la matriz de incidencia y deduce una afirmación que se cumple en *todos* los marcados, alcanzables o no, antes de que exista ningún marcado. La misión prometía que la lección 5 volvería a demostrar el búfer acotado «sin mirar ni un solo marcado». Eso es un invariante de plazas.

Ya escribes de estos. Un invariante de bucle es una afirmación que sobrevive a cada iteración; un invariante de una red de Petri es una afirmación que sobrevive a cada disparo. La diferencia es que este no lo tienes que adivinar: sale de una matriz.

## La única línea de álgebra

La lección 2 dio la ecuación de estado. Si un marcado *M* se alcanza desde *M0* disparando cada transición *x(t)* veces, entonces

*M* = *M0* + *C x*

Toma cualquier vector fila *y* de la longitud adecuada y multiplica los dos lados por él:

*y M* = *y M0* + *y C x*

Ahora elige *y* de forma que **y C = 0**. El último término desaparece sea cual sea *x*, y te queda

*y M* = *y M0*

para todo *M* que la ecuación pueda alcanzar — lo que incluye todos los marcados alcanzables, porque todo marcado alcanzable satisface la ecuación. Un *y* así es un **invariante de plazas**, o P-semiflujo cuando se exige que los pesos sean no negativos. Es un recuento ponderado de marcas que ningún disparo puede cambiar.

Esa es toda la deducción, y merece la pena fijarse en lo que *no* ha usado: ningún marcado, ningún orden de disparo, ninguna sensibilización. Los pesos *y* dependen solo de los arcos.

## Lo que el productor y el consumidor conserva

El analizador los calcula a partir de *C* por **eliminación de Farkas**, el método que describe Murata (1989, sección V-B): empezar con una fila por plaza, etiquetada con un vector unitario; eliminar una columna de *C* cada vez sumando pares de filas con signos opuestos en esa columna; lo que sobrevive son los generadores no negativos. Solo se conservan los de soporte minimal, de modo que se informa de `free + full = 2` en vez de sus infinitos múltiplos y sumas.

```
== What the producer and consumer never stops conserving ==
invariants of producer-consumer
  place invariants (3):
    ready + produced = 1
    free + full = 2
    waiting + taken = 1
  transition invariants (1):
    produce + deposit + take + consume
places: 6   rank of C: 3   dimension of the solutions of y C = 0: 3
```

Lee los tres como frases sobre el sistema:

- `ready + produced = 1` — el productor está exactamente en uno de sus dos estados. Es un booleano, y el invariante es la prueba de que lo es.
- `free + full = 2` — el búfer tiene dos huecos, y cada hueco está libre u ocupado. Nada crea un hueco, nada destruye ninguno.
- `waiting + taken = 1` — el consumidor, igual que el productor.

La última línea del bloque es una comprobación de cordura sobre cuántos esperar. Las soluciones de *y C* = 0 forman un espacio vectorial de dimensión (número de plazas) − rango(*C*) = 6 − 3 = 3, y aquí los tres invariantes minimales resultan ser una base de él. Esa coincidencia no es general: una red puede tener más semiflujos minimales que la dimensión del espacio, porque la minimalidad va de soportes y no de independencia lineal.

## La prueba

`free + full = 2` y nada más da la promesa de la lección 1:

```
== The proof that the buffer cannot overflow ==
invariant     free + full = 2
both counts are numbers of tokens, so free >= 0 and full >= 0
therefore     full <= 2 at every reachable marking, and at every marking at all
markings enumerated to get there: 0
checking it anyway on the graph of lesson 3: 12 markings, invariant holds in all: True
largest value of full among them: 2
```

Dos hechos, una línea de aritmética. `full` es como mucho 2 porque `free` no puede ser negativo y los dos suman 2. Es una prueba sobre un conjunto de marcados que nadie ha enumerado, y se leería exactamente igual si el búfer tuviera una capacidad de un millón.

Compáralo con lo que hizo la lección 3: doce marcados, cada uno construido disparando, cada uno comparado con los anteriores. Para una capacidad *k*, eso son 4·(*k*+1) marcados — la lección 7 los tabula — y el invariante sigue siendo una línea.

Las dos últimas líneas del bloque son el curso comprobando su propia afirmación. No forman parte de la prueba; están ahí porque una prueba que no coincide con el programa es una prueba con un error dentro.

## Cada plaza, de tres maneras

El mismo razonamiento aplicado a cada plaza da una cota sin grafo: si un invariante *y* cubre *p*, entonces *y(p)·M(p)* es como mucho *y M0*, así que *M(p)* es como mucho *y M0 / y(p)*. El analizador toma la menor de esas cotas sobre todos los invariantes:

```
== The bound of every place, three ways ==
bounds of producer-consumer
place     invariants              coverability tree   reachability graph
ready     1                       1                   1
produced  1                       1                   1
free      2                       2                   2
full      2                       2                   2
waiting   1                       1                   1
taken     1                       1                   1
  markings enumerated: 0 for the invariants, 12 for the graph
```

Tres métodos, los mismos seis números, y la columna de la izquierda no ha pagado nada por ellos.

Ahora quita la plaza `free`, como hizo la lección 3, y vuelve a preguntar:

```
== The same table on the net with the brake removed ==
invariants of unbounded-producer
  place invariants (2):
    ready + produced = 1
    waiting + taken = 1
  transition invariants (1):
    produce + deposit + take + consume
bounds of unbounded-producer
place     invariants              coverability tree   reachability graph
ready     1                       1                   still growing at 500
produced  1                       1                   still growing at 500
full      not covered             unbounded           still growing at 500
waiting   1                       1                   still growing at 500
taken     1                       1                   still growing at 500
  markings enumerated: 0 for the invariants, 500 for the graph
```

El invariante que acotaba el búfer ha desaparecido, y la plaza que acotaba es la que crece. Es el mismo hecho que la lección 1 te contó en imágenes — la *ausencia* de una plaza es lo que hacía que la cola no estuviera acotada — ahora enunciado como la ausencia de una ley de conservación.

:::caution[Lo que «not covered» no significa]
`not covered` dice que el analizador no encontró ningún invariante de plazas que dé peso a `full`. **No** dice que la plaza no esté acotada. Hay redes acotadas cuya cota ningún P-semiflujo puede expresar; la acotación estructural se caracteriza por una condición distinta (un vector positivo *y* con *y C* ≤ 0, no *y C* = 0), e incluso esa va sobre todos los marcados iniciales y no sobre este. Aquí el árbol de cobertura de la lección 3, que es un procedimiento de decisión, es lo que demuestra que `full` no está acotada. El invariante solo dejó de demostrar lo contrario.
:::

## Lo que un invariante no puede hacer

Un invariante es una consecuencia de la ecuación de estado. Así que hereda la debilidad a la que la lección 2 dedicó una sección: todo lo que la ecuación acepta, los invariantes también lo aceptan.

```
== An invariant cannot exclude what the state equation accepts ==
invariants of handshake
  place invariants (1):
    request + response = 0
  transition invariants (0):
spurious marking (0, 0, 1)  served:1  satisfies every place invariant: True
spurious marking (0, 0, 2)  served:2  satisfies every place invariant: True
```

Los dos marcados que la red `handshake` no puede alcanzar satisfacen su invariante a la perfección. Ningún conjunto de invariantes de plazas excluirá jamás una solución espuria, porque los invariantes de plazas son estrictamente más débiles que la ecuación que los produjo, y la ecuación ya es estrictamente más débil que la alcanzabilidad. Si la lección 2 te dejó con la esperanza de que los invariantes cerraran ese hueco, no lo hacen — la lección 6 es donde el hueco empieza a cerrarse, con sifones y trampas.

La segunda limitación importa más en la práctica: **los invariantes demuestran seguridad, nunca vivacidad.** Estos son los cuatro invariantes de la red que se interbloquea de la lección 4:

```
== What invariants do not see: the deadlock of two locks ==
invariants of two-locks
  place invariants (4):
    a_idle + a_has_x = 1
    a_has_x + x = 1
    b_idle + b_has_y = 1
    b_has_y + y = 1
  transition invariants (2):
    a_take_x + a_take_y
    b_take_y + b_take_x
dead marking (0, 1, 0, 1, 0, 0)  a_has_x:1 b_has_y:1
every place invariant above holds there too: True
```

Los cuatro son ciertos en el interbloqueo. Tienen que serlo — son ciertos en todas partes, y el interbloqueo es un marcado como cualquier otro. Un invariante puede decirte «este marcado malo es imposible» cuando el marcado incumple el recuento; nunca puede decirte «este marcado alcanzable es malo», porque aquí lo malo va de lo que la red *no puede hacer a continuación*, y un recuento conservado no dice nada sobre el futuro.

`a_has_x + x = 1` es la lectura útil de ese bloque: el cerrojo `x` o lo tiene A o está libre, nunca las dos cosas, nunca ninguna. *Eso* sí merece demostrarse, y es exactamente el tipo de afirmación para el que están los invariantes.

## Invariantes de transiciones

Transpón la pregunta. Un **invariante de transiciones**, o T-semiflujo, es un vector de enteros no negativos *x* con **C x = 0**: un multiconjunto de disparos cuyo efecto neto sobre el marcado es ninguno.

```
== Transition invariants: the firings that cancel out ==
x = (1, 1, 1, 1)   produce + deposit + take + consume
firing it once from M0 gives (1, 0, 2, 0, 1, 0), back to (1, 0, 2, 0, 1, 0): True
```

Una vuelta completa por el sistema lo deja exactamente como estaba. Esa es la definición de un ciclo en lo que se está modelando — una petición servida, un mensaje consumido, un cerrojo tomado y soltado.

La trampa es la misma que la lección 2 ya enseñó sobre la ecuación de estado, en el otro sentido: *C x* = 0 dice que la aritmética se cancela, no que algún orden de esos disparos pueda ejecutarse realmente.

```
two locks has two of them, and a marking from which neither can be fired at all:
  x = (1, 1, 0, 0)   a_take_x + a_take_y
  x = (0, 0, 1, 1)   b_take_y + b_take_x
  transitions enabled at the dead marking: (nothing)
```

Los dos T-invariantes existen, los dos describen una vuelta perfectamente sensata — tomar los dos cerrojos, soltar los dos cerrojos — y desde el interbloqueo ninguno de ellos puede empezar.

El caso interesante es el contrario:

```
the handshake has none at all, and that is a statement about its runs:
  transition invariants of handshake: 0
  transition invariants of handshake-started: 0
  a marking it can reach twice: False
  a marking the producer and consumer can reach twice: True
```

La red `handshake` **no** tiene ningún invariante de transiciones, y eso es una afirmación real sobre su comportamiento: ninguna secuencia no vacía de disparos puede devolver la red a un marcado en el que ya haya estado, porque cada `receive` deja caer una marca en `served` y nada la saca. Una red sin T-invariante no tiene ningún ciclo en su grafo de alcanzabilidad. El analizador lo comprueba directamente sobre el prefijo de 500 marcados de `handshake-started`: no encontró ningún marcado alcanzable dos veces, mientras que el productor y el consumidor tiene muchos.

Ese no necesita ningún teorema para creérselo. Si una red es reversible y puede disparar algo, entonces alguna secuencia no vacía la devuelve a *M0*; el vector que cuenta esos disparos es no negativo, no nulo, y satisface *C x* = 0. Así que es un invariante de transiciones. Dale la vuelta: **sin invariante de transiciones, no hay retorno**. Es el único hecho cercano a la vivacidad que esta lección consigue gratis, y la lección 6 es de donde viene el resto.

## Puntos clave

- Un **invariante de plazas** es un vector *y* con *y C* = 0. Entonces *y M* = *y M0* en todo marcado que la ecuación de estado pueda alcanzar, y por tanto en todo marcado alcanzable. Es un invariante de bucle que no tienes que adivinar.
- `free + full = 2` más «los recuentos de marcas no son negativos» demuestra que el búfer no puede desbordarse, **con cero marcados enumerados**, y la prueba no crece con la capacidad.
- Los invariantes de plazas dan **cotas** gratis: *M(p)* ≤ *y M0 / y(p)*. Una plaza que ningún invariante cubre es una plaza sin prueba, no una plaza demostradamente no acotada.
- Los invariantes son **consecuencias de la ecuación de estado**, así que aceptan toda solución espuria. Demuestran propiedades de seguridad y nunca de vivacidad: los cuatro invariantes de `two-locks` se cumplen en su interbloqueo.
- Un **invariante de transiciones** es un vector *x* con *C x* = 0: disparos que se cancelan. No promete que la secuencia pueda dispararse. No tener ninguno, como le pasa a `handshake`, demuestra que la red nunca puede volver a un marcado que haya dejado.
- Los dos se calculan por **eliminación de Farkas** sobre *C*, en [`Invariants.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Invariants.cs), sin construir nada.

## Ejercicios

1. La red de exclusión mutua tiene el invariante `critical1 + critical2 + mutex = 1`. Escribe, en una frase y sin mencionar las redes de Petri, la propiedad del programa de C# que esto demuestra. Luego di qué línea del programa tendría que cambiar para que el invariante pasara a ser `= 2`, y qué se rompería.
2. La red de lectores y escritores de la lección 7 tiene dos invariantes de plazas. Uno de ellos es `reading + 3*writing + access = 3`. ¿Qué demuestra sobre el número de escritores, y por qué aparece el peso 3?
3. Una red modela un flujo de trabajo: empieza con una marca en `start` y debería terminar con una marca en `end`. Alguien afirma que «el invariante `start + working + end = 1` demuestra que el flujo de trabajo termina». Di con precisión qué demuestra y qué no.
4. Toma la red `emit-loop` de la lección 3 — una transición que devuelve su marca de entrada y llena dos plazas. Predice sus invariantes de plazas antes de ejecutar el analizador, y luego comprueba.

<details>
<summary>Soluciones</summary>

**1.** «Como mucho un hilo está dentro de la sección crítica en cada momento, y el cerrojo está libre exactamente cuando no lo está ninguno.» La plaza `mutex` es el objeto del cerrojo; `= 1` es el hecho de que hay uno. Para hacerlo `= 2` pondrías dos marcas en `mutex` al principio, lo que en código es sustituir `lock (gate)` por `new SemaphoreSlim(2)`. Lo que se rompe es lo que sea que proteja la sección crítica: dos hilos estarían dentro a la vez, que es justo para lo que el recuento vale 1. La lección 7 construye exactamente esa red y la mide.

**2.** Demuestra que `writing` es como mucho 1: como `reading` y `access` no pueden ser negativos, 3·`writing` no puede pasar de 3. El peso 3 aparece porque `start_write` toma los tres permisos de `access` por un arco de peso 3 — el invariante tiene que dar a un escritor el peso de lo que consume, que es exactamente lo que hace que «un escritor excluye a tres lectores» sea aritmética y no una regla que alguien se acordó de imponer.

**3.** Demuestra que el flujo de trabajo está exactamente en uno de los tres estados en cada momento, y por tanto que nunca se ejecuta dos veces a la vez y nunca desaparece en silencio. No demuestra **nada** sobre la terminación: el marcado `working = 1` satisface el invariante para siempre, y una red que se queda ahí es un flujo de trabajo colgado. La terminación es una propiedad de vivacidad; la lección 10 la define como es debido dentro de la *soundness*, y necesita el grafo de alcanzabilidad o un teorema estructural, no un invariante.

**4.** No hay ninguno cuyo soporte contenga `log` o `queue`, porque `emit` solo les añade: cualquier *y* con *y C* = 0 tiene que tener *y(log)* = *y(queue)* = 0. El único invariante es sobre `ready` a solas — `emit` toma una marca de `ready` y la devuelve de inmediato, así que la columna de *C* es nula ahí, y `ready = 1` se conserva. Dos de las tres plazas no tienen ley de conservación, y son exactamente las dos que el árbol de cobertura de la lección 3 marcó con ω.

</details>

## Fuentes

- Tadao Murata, *Petri nets: Properties, analysis and applications*, **Proceedings of the IEEE** 77(4), abril de 1989, páginas 541–580, [doi:10.1109/5.24143](https://doi.org/10.1109/5.24143). La sección V-B es la referencia para los invariantes de plazas y de transiciones y para la eliminación de Farkas que se usa aquí. El registro está confirmado a través de Crossref; el artículo está tras el muro de pago de la IEEE y no lo he leído, así que nada en esta lección se apoya solo en él — todo lo anterior o se deduce en el texto o lo imprime el analizador. *Por verificar.*
- Wolfgang Reisig, *Understanding Petri Nets*, Springer, 2013, [doi:10.1007/978-3-642-33278-4](https://doi.org/10.1007/978-3-642-33278-4), por presentar los invariantes de plazas como la técnica de prueba principal y no como un añadido. *Por verificar* — registro comprobado, libro no leído.
- La implementación que imprime esta lección: [`Invariants.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Invariants.cs), con las pruebas unitarias que comprueban cada invariante contra cada marcado alcanzable en [`PetriNetTests.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/Tests/PetriNetTests.cs).
