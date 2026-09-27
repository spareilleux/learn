---
title: "16. Interoperabilidad: preservar el comportamiento, no solo el dibujo"
description: Un modelo PNML de admisión de agentes escrito a mano, leído, analizado, escrito y releído, y comparado por lo que hace y no por su aspecto; el mismo modelo con la liberación olvidada; dos ficheros mal formados; y un arco inhibidor que el lector se tragaba sin decir nada.
sidebar:
  order: 16
---

Código completo: [`code/petri-nets`](https://github.com/spareilleux/learn/tree/main/code/petri-nets). Esta lección la imprime `dotnet run --project Examples -c Release -- l16`, y se compara con [`expected/l16.txt`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/expected/l16.txt). Sus ficheros de entrada, y las predicciones escritas antes de la primera ejecución, están en [`interop/`](https://github.com/spareilleux/learn/tree/main/code/petri-nets/interop).

La [lección 11](../11-tools-and-interoperability/) mostró dos cosas:
- PNML es una sintaxis más una URI de tipo;
- cada red del curso sobrevive a una ida y vuelta por el escritor y el lector, byte a byte.

Eso probaba el escritor contra su propio lector. Esta lección plantea la pregunta que trae una segunda herramienta: una vez que una red ha pasado por un fichero, ¿sigue **haciendo** lo mismo? El dibujo puede moverse. El comportamiento, no.

## Tres tipos de fichero, tres tipos de promesa

Los ficheros que «contienen una red de Petri» contienen tres cosas distintas, y solo una puede comprobarse en su comportamiento.

| Tipo | Qué contiene | Qué te puede decir | Formato de ejemplo |
|---|---|---|---|
| Un modelo | plazas, transiciones, arcos y sus pesos, marcado inicial | todas las ejecuciones que la red permite | [PNML](https://www.pnml.org/) de tipo P/T, el `.net` de [TINA](https://projects.laas.fr/tina/manuals/tina.html) |
| Un registro de eventos | casos y los eventos que ocurrieron en ellos, en orden | las ejecuciones **observadas**, no las que eran posibles | XES, que escribe el [`write_xes` de pm4py](https://processintelligence.solutions/app/static/api/2.7.17/api/pm4py.write.html) |
| Una exportación visual | nodos, aristas, posiciones, etiquetas | la imagen | [DOT](https://graphviz.org/doc/info/lang.html), el lenguaje de Graphviz |

- **Un registro es evidencia sobre algunas ejecuciones.** De él se puede extraer un modelo: es el process mining de la [lección 10](../10-workflows/). El registro no contiene el modelo: una ejecución que nunca ocurrió no está en él.
- **La gramática de DOT define nodos, aristas, grafos, subgrafos y clusters, con atributos.** Un número de marcas escrito en un fichero DOT es una etiqueta; nada lo lee como un marcado.

**PNML tiene tipo, y el tipo no es una promesa.** La URI de tipo le dice al lector en qué lenguaje está el fichero. No promete que el lector implemente cada extensión que una herramienta pueda añadir encima.

Dos fuentes primarias muestran cuánto depende el intercambio de la herramienta:
- **El manual de TINA** dice que `tina` lee una red en forma textual (`.net`, `.pnml`, `.tpn`) o gráfica (`.ndr`, o `.pnml` con gráficos). Tiene una opción, `-inh`, que *«elimina los arcos inhibidores y de lectura de la red de entrada»*. Allí, abandonar parte de la semántica es una opción que el usuario pide por su nombre.
- **El `write_pnml` de pm4py** recibe un marcado inicial **y un marcado final**. Escribe la vista de red de workflow de la lección 10, que una red P/T sin más no tiene.

## El modelo

Dos jobs de agente comparten un paso de admisión que solo uno puede ocupar a la vez. Un job necesita un candidato probado antes de ser admitido, y devuelve su capacidad cuando termina.

| Plaza | Inicial | Significado |
|---|---|---|
| `waiting` | 2 | jobs cuyo candidato aún no se ha probado |
| `tested` | 0 | jobs cuyo candidato pasó sus pruebas: el requisito de la admisión |
| `capacity` | 2 | huecos libres; un job necesita 2, así que solo corre un job a la vez |
| `running` | 0 | jobs admitidos |
| `done` | 0 | jobs terminados |

| Transición | Consume | Produce |
|---|---|---|
| `test` | `waiting` | `tested` |
| `admit` | `tested`, `capacity` ×2 | `running` |
| `finish` | `running` | `done`, `capacity` ×2: la liberación |

[`admission.pnml`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/interop/admission.pnml) se escribió a mano, no con el escritor de este curso. Está escrito como lo escribiría una herramienta de dibujo: una posición `<graphics>` en cada nodo, y el nombre de la red en la `<page>`.

A diferencia de las lecciones anteriores del curso, las predicciones se guardaron en un fichero antes de la primera ejecución: [`preregistration.md`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/interop/preregistration.md), con hash tomado a las 10:54 EDT del 2026-09-27. Todas se cumplieron.

## E1: leer, analizar, escribir, releer

El programa calcula lo que la red **significa**, como líneas que se pueden comparar. Lo hace tras la primera lectura, y otra vez tras escribir la red y releerla:

```text
== E1: the admission net, read, written and read again ==
places:      waiting tested capacity running done
transitions: test admit finish
initial:     waiting=2 tested=0 capacity=2 running=0 done=0
arcs:        waiting->test, test->tested, tested->admit, capacity->admit x2, admit->running, running->finish, finish->done, finish->capacity x2
enabled:     test
states:      9
dead:        waiting=0 tested=0 capacity=2 running=0 done=2  after test test admit finish admit finish
bounds:      waiting<=2 tested<=2 capacity<=2 running<=1 done<=2
capacity + 2*running = 2 in every state: yes
after the round trip, same meaning: yes
second write identical to the first: yes
positions in the input: 9, in the output: 0
```

- **Lo que sobrevive:**
  - los identificadores;
  - el marcado;
  - los dos pesos de 2;
  - el conjunto de transiciones habilitadas;
  - los 9 marcados alcanzables;
  - el único marcado muerto;
  - las cotas.
- **El marcado muerto es el final previsto:** los dos jobs están terminados y la capacidad ha vuelto a 2.
- **`running<=1` es la propiedad para la que existe el modelo.** Nunca hay doble admisión. La suma conservada `capacity + 2·running = 2` es el mismo hecho escrito como invariante ([lección 5](../05-invariants/)).
- **Las 9 posiciones han desaparecido,** porque el escritor descarta la disposición (lección 11). No es un fallo: nada en la comparación depende de dónde se dibuja una plaza.

Lo que cubre esta comparación es el **comportamiento alcanzable acotado**: se enumeran los 9 marcados, sin dejar ninguno fuera. No es una ejecución de jobs reales. Tampoco es una prueba de equidad: el grafo dice que un job en espera *puede* terminar, no que un planificador lo vaya a dejar ([lección 4](../04-properties/)).

## E2: la liberación olvidada

[`admission-no-release.pnml`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/interop/admission-no-release.pnml) es la misma red, con un `finish` que solo produce `done`:

```text
== E2: the same net with the release forgotten ==
states:      7
dead:        waiting=0 tested=1 capacity=0 running=0 done=1  after test test admit finish
bounds:      waiting<=2 tested<=2 capacity<=2 running<=1 done<=1
```

- **El marcado muerto no es un final.** Un job está probado y nunca será admitido, porque la capacidad que espera nunca se devolvió.
- **El camino es la parte útil: `test test admit finish`.** Es un contraejemplo que cualquiera puede reproducir, en este analizador o en otra herramienta, y señala la transición que olvidó algo.

## E3: ficheros erróneos

```text
malformed-arc.pnml      refused: ArgumentException: Arc finish -> finished does not join a place and a transition. (Parameter 'arcs')
malformed-marking.pnml  refused: FormatException: The input string 'two' was not in a correct format.
```

- **Los dos ficheros se rechazan, como se predijo:** un arco hacia un nodo que no existe, y un marcado inicial escrito `two`.
- **El segundo mensaje es el de `int.Parse`.** No dice qué plaza estaba mal. Queda observado y se deja así: el rechazo es correcto, solo su redacción es pobre.

## E4: una característica que el lector no modela

Un arco inhibidor solo deja disparar una transición cuando una plaza está **vacía** ([lección 15](../15-limits-and-what-comes-next/)). No forma parte de la gramática P/T.

[`inhibitor-arc.pnml`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/interop/inhibitor-arc.pnml) sustituye la plaza de capacidad por un arco así, de `running` a `admit`. El arco lleva un hijo `<type>`, como hacen las herramientas que modelan más que redes P/T para marcar el tipo de un arco:

```xml
<arc id="r-inhibits-admit" source="running" target="admit">
  <type value="inhibitor"/>
</arc>
```

Antes de esta lección, el lector aceptaba el fichero:

```text
inhibitor-arc.pnml      READ: 3 states, dead: waiting=0 tested=2 running=0 done=0
```

**Es otra red.** El lector tomó el arco inhibidor por un arco ordinario que consume. Así, `admit` exigía un job ya en marcha, nunca se admitía ningún job, y la red se detenía con los dos jobs probados.

No hubo ni error ni aviso. Es el peor desenlace posible de un intercambio: un fichero que se lee, y que significa otra cosa.

El lector ahora rechaza cualquier arco cuyo tipo no sea `normal`, y dice por qué ([`Pnml.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Pnml.cs)):

```csharp
var kind = (string?)element.Element(ns + "type")?.Attribute("value");
if (kind is not null && kind != "normal")
    throw new NotSupportedException($"Arc {(string?)element.Attribute("id") ?? $"{source} -> {target}"} is of type {kind}; the P/T reader reads ordinary arcs only.");
```

```text
inhibitor-arc.pnml      refused: NotSupportedException: Arc r-inhibits-admit is of type inhibitor; the P/T reader reads ordinary arcs only.
```

Una prueba unitaria, `An_arc_the_reader_does_not_model_is_refused_not_read_as_an_ordinary_arc`, fija la corrección:
- fallaba antes de la corrección (1 de las 5 pruebas PNML);
- pasa después (5 de 5), y todo el curso también (92 pruebas, 19 salidas comparadas).

Un arco con tipo `normal` se sigue leyendo: dice que el arco es ordinario, y la prueba lo comprueba como control.

## Lo que no se ejecutó aquí

**TINA no está instalado en esta máquina, ni pm4py ni Graphviz tampoco.** El paso siguiente es una receta, no un resultado:

```bash
# Pendiente: TINA no está instalado en esta máquina. Este comando no se ha ejecutado.
tina -R interop/admission.pnml
```

- **Qué comprobaría.** `-R` construye el grafo de marcados alcanzables. Sus cuentas deberían coincidir con las de E1: 9 marcados, un marcado muerto, aquel en que los dos jobs han terminado.
- **Qué más sería un resultado:**
  - `inhibitor-arc.pnml` leído por TINA, que sí modela arcos inhibidores;
  - el mismo fichero con `-inh`.
- **También pendientes:**
  - un registro XES de ejecuciones simuladas, contrastado con el modelo;
  - una imagen DOT, que no comprobaría nada del comportamiento.

## Puntos clave

- **Compara lo que una red significa, no el aspecto de su fichero:** identificadores, marcado, pesos, transiciones habilitadas, marcados alcanzables, marcados muertos y cotas.
- **Un registro guarda ejecuciones, un dibujo guarda posiciones; solo un modelo guarda comportamiento.**
- **El peor fallo es silencioso.** Una red que se lee y significa otra cosa es peor que un rechazo. Rechaza lo que no modelas, y di qué era.
- **Un marcado muerto con su camino es un contraejemplo que se puede reproducir.** Un espacio de estados no es ni una ejecución ni una prueba de equidad.

## Ejercicios

1. Dale al modelo tres jobs (`waiting` = 3). Predice el número de marcados alcanzables antes de ejecutarlo, y luego compruébalo.
2. E1 tiene un marcado muerto, y nadie lo llama interbloqueo. ¿Por qué no, y qué haría explícita la diferencia?
3. Un arco con tipo `<type value="reset"/>` vacía su plaza. ¿Qué hace el lector con él ahora, y qué habría hecho antes de esta lección?
4. ¿Cuál de estas cosas demuestra que dos herramientas coinciden en una red? Un texto PNML idéntico; un DOT idéntico; números de estados idénticos; grafos de alcanzabilidad idénticos salvo renombrado de los marcados.

<details>
<summary>Soluciones</summary>

**1.** Dieciséis. Corre como mucho un job, porque `running<=1`.
- Con `running = 0`, los tres jobs se reparten entre `waiting`, `tested` y `done`: C(5, 2) = 10 formas.
- Con `running = 1`, los otros dos se reparten igual: C(4, 2) = 6 formas.

Ejecutado sobre una copia de `interop/` con `waiting` puesto a 3:

```text
initial:     waiting=3 tested=0 capacity=2 running=0 done=0
states:      16
dead:        waiting=0 tested=0 capacity=2 running=0 done=3  after test test test admit finish admit finish admit finish
bounds:      waiting<=3 tested<=3 capacity<=2 running<=1 done<=3
capacity + 2*running = 2 in every state: yes
```

**2.** El marcado muerto de E1 es el final buscado: cada job ha terminado y la capacidad ha vuelto. Un interbloqueo es un marcado muerto que **no** es el final buscado, como el de E2.

La red sola no puede distinguirlos. Un **marcado final** sí: es lo que añade una red de workflow (lección 10), y por eso `pm4py.write_pnml` pide uno.

**3.** Se rechaza:

```text
inhibitor-arc.pnml      refused: NotSupportedException: Arc r-inhibits-admit is of type reset; the P/T reader reads ordinary arcs only.
```

Antes de la corrección, el lector solo leía `source`, `target` e `inscription`. Habría tomado el arco por uno ordinario, que consume una marca en lugar de vaciar la plaza. Es el mismo cambio silencioso que con el arco inhibidor.

**4.** Solo la última.
- **El texto** no es ni necesario ni suficiente. La disposición, los identificadores y el orden de los elementos pueden diferir para una misma red. Y dos lectores pueden leer distinto el mismo texto, como hizo este lector con E4 antes de la corrección.
- **DOT** no dice nada del comportamiento.
- **Números iguales** son necesarios, no suficientes.
- **Grafos de alcanzabilidad idénticos salvo renombrado**, con las transiciones etiquetadas, son el enunciado de comportamiento para una red acotada.

</details>

## Fuentes

- [PNML](https://www.pnml.org/), el sitio del formato, e ISO/IEC 15909-2:2011, citada en la lección 11.
- [Manual de TINA](https://projects.laas.fr/tina/manuals/tina.html), LAAS-CNRS: formatos de entrada, `-R`, `-inh`. Leído el 2026-09-27; TINA no se ejecutó.
- [pm4py 2.7.17, `pm4py.write`](https://processintelligence.solutions/app/static/api/2.7.17/api/pm4py.write.html): las firmas de `write_pnml` (marcado inicial y final) y de `write_xes`. Leído el 2026-09-27; pm4py no se ejecutó.
- [El lenguaje DOT](https://graphviz.org/doc/info/lang.html), Graphviz: una gramática abstracta para nodos, aristas, grafos, subgrafos y clusters.
