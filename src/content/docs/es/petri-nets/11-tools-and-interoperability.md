---
title: 11. Herramientas e interoperabilidad
description: PNML es lo único en lo que todas las herramientas de redes de Petri están de acuerdo — qué escribe el analizador, qué conserva y qué pierde una ida y vuelta, qué pasó cuando se le dieron dieciséis ficheros escritos por otra herramienta, el defecto que eso encontró, y qué hacen TINA, LoLA, CPN Tools, GreatSPN, TAPAAL y ProM que este curso no hace.
sidebar:
  order: 11
---

Código completo: [`code/petri-nets`](https://github.com/spareilleux/learn/tree/main/code/petri-nets). Esta lección la imprime `dotnet run --project Examples -c Release -- l11`, y se compara con [`expected/l11.txt`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/expected/l11.txt).

Diez lecciones se han escrito contra un analizador que escribí yo, sobre redes que también escribí yo. Eso es un circuito cerrado, y un circuito cerrado es la forma en que un curso enseña calladamente sus propios errores.

La salida de ese circuito se llama [PNML](https://www.pnml.org/), el Petri Net Markup Language — un formato XML normalizado como [ISO/IEC 15909-2:2011](https://www.iso.org/standard/43538.html) y lo único en lo que las herramientas de este campo están de acuerdo. Una red escrita aquí puede comprobarla un model checker escrito por otra persona, y una red de un banco de pruebas publicado puede pasar por el analizador de este curso.

Esta lección recorre los dos sentidos y cuenta qué se rompió.

## Qué emite el escritor

```
== What the writer emits ==
<?xml version="1.0" encoding="utf-8"?>
<pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
  <net id="n1" type="http://www.pnml.org/version-2009/grammar/ptnet">
    <name>
      <text>queue-2</text>
    </name>
    <page id="page1">
      <place id="room">
        <name>
          <text>room</text>
        </name>
        <initialMarking>
          <text>2</text>
        </initialMarking>
      </place>
      <place id="jobs">
        <name>
          <text>jobs</text>
        </name>
      </place>
      <transition id="arrive">
        <name>
          <text>arrive</text>
        </name>
      </transition>
      <transition id="serve">
        <name>
          <text>serve</text>
        </name>
      </transition>
      <arc id="a1" source="room" target="arrive" />
      <arc id="a2" source="arrive" target="jobs" />
      <arc id="a3" source="jobs" target="serve" />
      <arc id="a4" source="serve" target="room" />
    </page>
  </net>
</pnml>
```

Cuatro cosas de ese fichero merecen nombre, porque cada una es un punto en el que las herramientas discrepan.

- **el atributo `type`** es una URI, y es todo el contrato. `…/grammar/ptnet` significa red plaza/transición: marcas indistinguibles, arcos con pesos enteros. Otra URI es otro lenguaje en la misma sintaxis, y el lector debe rechazarla en vez de adivinar.
- **`<page>`** existe porque PNML modela un *dibujo*, y los dibujos tienen páginas. El analizador no tiene uso para las páginas y escribe exactamente una; un fichero que llega con varias se aplana.
- **todo valor va envuelto en `<text>`**, porque la norma permite que un valor lleve gráficos, una fuente, una anotación propia de una herramienta y un desplazamiento de etiqueta junto a su contenido. El número nunca es el texto propio del elemento.
- **la ausencia significa el valor por defecto.** `jobs` no tiene `<initialMarking>` y contiene cero; los arcos no tienen `<inscription>` y pesan uno. Escribirlos sería legal y más ruidoso.

## Releer lo que escribimos

La interoperabilidad empieza en casa. Si el lector y el escritor discrepan, ninguna otra herramienta importa:

```
== Every net of the course, written and read back ==
24 nets written, parsed and written again
identical text and identical reachability graph: all of them
```

Veinticuatro redes, cada una escrita en PNML, releída y vuelta a escribir. Los dos textos son idénticos byte a byte y el grafo de alcanzabilidad tiene el mismo número de estados. `check.sh` lo comprueba en cada commit, lo que hace de los ficheros PNML de [`nets/`](https://github.com/spareilleux/learn/tree/main/code/petri-nets/nets) los mismos objetos que las definiciones en C#, y no una copia que se desvía.

Una ida y vuelta no es sin pérdidas, y decirlo explícitamente es el asunto:

```
== What a round trip drops ==
kept:    place and transition ids and names, arc weights, the initial marking
dropped: <graphics> positions and offsets, <toolspecific> blocks, page structure
refused: any <net type> that is not the P/T net type
```

Todo lo que se pierde tiene que ver con *dibujar* la red, no con lo que hace. Lee un fichero de un editor gráfico, analízalo, vuélvelo a escribir: la disposición ha desaparecido, la red es la misma red y el dibujo hay que rehacerlo. Ese es el coste honesto de una herramienta que modela las matemáticas y no el diagrama.

## Leer un fichero escrito por otra persona

La prueba de verdad. [ePNK](http://www2.imm.dtu.dk/~eki/projects/ePNK/) es una herramienta PNML sobre Eclipse de Ekkart Kindler, uno de los autores de la norma; su paquete de ejemplos incluye el ejemplo de red P/T de la propia ISO/IEC 15909-2, más quince redes de alto nivel. Dieciséis ficheros, ninguno mío:

```
== Reading another tool ==
ConsensusInNetworks.pnml              refused: Net type highlevelnet is not the P/T net type ptnet.
Echo.pnml                             refused: Net type highlevelnet is not the P/T net type ptnet.
MinDistance.pnml                      refused: Net type highlevelnet is not the P/T net type ptnet.
SimpleTransmissionProtocol.pnml       refused: Net type highlevelnet is not the P/T net type ptnet.
TransmissionProtocolLossyChannel.pnml refused: Net type highlevelnet is not the P/T net type ptnet.
factorize.pnml                        refused: Net type highlevelnet is not the P/T net type ptnet.
factorize2.pnml                       refused: Net type highlevelnet is not the P/T net type ptnet.
lists.pnml                            refused: Net type highlevelnet is not the P/T net type ptnet.
prime-factors.pnml                    refused: Net type highlevelnet is not the P/T net type ptnet.
runtimeValueEval.pnml                 refused: Net type highlevelnet is not the P/T net type ptnet.
samplePTnet.pnml                      read: 1 places, 1 transitions, "An example P/T-net"
samplePTnetAdjustedPositions.pnml     read: 1 places, 1 transitions, "An example P/T-net"
sampleSNPrio.pnml                     refused: Net type symmetricnet is not the P/T net type ptnet.
sampleSNPrioDeclarationsOnPage.pnml   refused: Net type symmetricnet is not the P/T net type ptnet.
sampleSNPrioFixedNames.pnml           refused: Net type symmetricnet is not the P/T net type ptnet.
simple-dot-net.pnml                   refused: Net type pt-hlpng is not the P/T net type ptnet.
```

:::note[Este bloque no lo produce `check.sh`]
Los ejemplos de ePNK están bajo [EPL-1.0](https://www.eclipse.org/legal/epl-v10.html) y no se incluyen en este repositorio, así que `check.sh` ejecuta `l11` sin ellos y la sección imprime un aviso en su lugar. Para reproducirlo: descarga [`ePNK-1.0.0-examples.zip`](http://www2.imm.dtu.dk/~eki/projects/ePNK/downloads/ePNK-1.0.0-examples.zip), descomprime los ficheros `.pnml` en un directorio y ejecuta `dotnet run --project Examples -c Release -- l11 <ese directorio>`. El listado de arriba es de esa ejecución del 2026-09-22.
:::

Dos aceptados, catorce rechazados, y las dos mitades son el resultado.

**Los rechazos son correctos, y el último es el interesante.** `simple-dot-net.pnml` es una *red P/T* — un solo tipo de marca, sin datos — escrita en la gramática de alto nivel con el conjunto de colores `dot`, que tiene exactamente un valor. Se comporta como todas las redes de este curso y es ilegible para un lector que comprueba la URI de tipo. Tres de los rechazos son redes simétricas, es decir las redes coloreadas restringidas que nombró la [lección 8](../08-coloured-nets/). La moraleja es que «PNML» no es un formato: es una sintaxis más una URI de tipo, y una herramienta habla algunos de esos tipos.

**Las aceptaciones encontraron un defecto.** El fichero de ejemplo de la ISO, tal como lo escribe ePNK, está hecho a propósito para ser incómodo:

```xml
<net type="http://www.pnml.org/version-2009/grammar/ptnet" id="n1">
  <page id="top-level">
    <name><text>An example P/T-net</text></name>
    <place id="p1">
      <name><graphics><offset y="-10.0"/></graphics><text>ready</text></name>
      <initialMarking>
        <toolspecific tool="org.pnml.tool" version="1.0">…</toolspecific>
        <text>3</text>
      </initialMarking>
    </place>
    <transition id="t1"><graphics><position x="60.0" y="20.0"/></graphics></transition>
    <arc id="a1" source="p1" target="t1">
      <inscription><graphics><offset y="5.0"/></graphics><text>2</text></inscription>
    </arc>
  </page>
</net>
```

Cuatro trampas, y el lector sobrevivió a tres. El marcado vale 3 aunque un bloque `<toolspecific>` venga primero; el peso del arco vale 2 aunque un `<graphics>` venga primero; la transición no tiene `<name>` en absoluto y recurre a su identificador.

La cuarta lo pilló. **El nombre está en la `<page>`, no en el `<net>`**, y el lector solo miraba la red — así que el fichero volvía llamándose `n1`, su identificador. La norma permite el nombre en cualquiera de los dos, las herramientas difieren, y el analizador había elegido uno en silencio. Tres líneas lo arreglaron, una prueba unitaria lleva ahora toda la forma incómoda, y el listado de arriba es posterior a la corrección.

Ese es el único defecto que encontró esta lección, y lo encontró el único método que encuentra esta clase de defectos: leer un fichero que nadie de este repositorio escribió.

## Para qué sirven las demás herramientas

El analizador de este curso es un instrumento didáctico. Construye un grafo de alcanzabilidad en memoria con un límite duro, enumera sifones por fuerza bruta sobre los subconjuntos de plazas, y resuelve una cadena de Markov por eliminación de Gauss densa. Cada una de esas decisiones es el algoritmo equivocado a escala, a propósito, porque cada una es lo bastante corta como para leerse.

Estas son las herramientas que lo hacen bien. Ninguna es necesaria para este curso; todas hablan PNML, y la mayoría también su formato nativo.

| Herramienta | Para qué sirve | Formato nativo |
|---|---|---|
| [TINA](https://projects.laas.fr/tina/) | redes de Petri temporales en el sentido de Merlin, clases de estados, model checking LTL/CTL | `.net`, `.ndr`, lee PNML |
| [LoLA](https://theo.informatik.uni-rostock.de/theo-forschung/tools/lola/) | alcanzabilidad y CTL\* muy rápidas sobre redes P/T enormes, con conjuntos obstinados y simetrías | formato propio, lee PNML |
| [CPN Tools](https://cpntools.org/) | redes coloreadas con inscripciones en CPN ML, simulación, espacio de estados con simetrías | `.cpn`, exporta PNML |
| [GreatSPN](https://www.di.unito.it/~greatspn/index.html) | GSPN y análisis estocástico, los modelos de la [lección 9](../09-time-and-probability/) a escala | formato propio, lee PNML |
| [TAPAAL](https://www.tapaal.net/) | redes con arcos temporizados, verificación por traducción a autómatas temporizados | `.tapn`, lee PNML |
| [Snoopy](https://www-dssz.informatik.tu-cottbus.de/DSSZ/Software/Snoopy) | dibujo y simulación de varias clases de redes, fuerte en biología de sistemas | formato propio, exporta PNML |
| [PIPE](https://github.com/sarahtattersall/PIPE) | un editor y analizador en Java, el de código más fácil de leer | PNML nativamente |
| [ePNK](http://www2.imm.dtu.dk/~eki/projects/ePNK/) | la implementación de referencia del metamodelo de la norma | PNML nativamente |
| [ProM](https://promtools.org/) | minería de procesos, el otro sentido de la [lección 10](../10-workflows/) | registros XES, redes PNML |

El sitio donde verlas unas contra otras es el [Model Checking Contest](https://mcc.lip6.fr/), que las ejecuta cada año sobre una colección pública de redes, en PNML, con resultados publicados. Esa colección es además la respuesta honesta a «¿es rápido mi analizador?» — no lo es, y el concurso dice por cuánto. *Por verificar: no he enviado nada, ni ejecutado su conjunto de pruebas.*

## Dónde se detiene esto

- **Una sintaxis compartida no es una semántica compartida.** Todos los ficheros de arriba se analizan como XML. Catorce seguían siendo ilegibles, porque la URI de tipo nombra otro lenguaje. PNML hace *posible* el intercambio entre herramientas que implementan el mismo tipo; no hace portable toda red.
- **La norma tiene tres partes y la útil cuesta dinero.** La [parte 1](https://www.iso.org/standard/67235.html) da los conceptos, la [parte 2](https://www.iso.org/standard/43538.html) el formato de transferencia, la [parte 3](https://www.iso.org/standard/81504.html) las extensiones. Las gramáticas son libres en [pnml.org](https://www.pnml.org/) — pero solo el modelo básico y las que no dependen del tipo; la gramática P/T no está entre los `.rng` publicados, así que la salida del analizador no se ha validado nunca contra un esquema. *Por verificar.*
- **Nadie se pone de acuerdo sobre dónde vive la disposición.** Las posiciones están en `<graphics>` y son opcionales, así que una red intercambiada entre dos editores suele llegar amontonada. Cada herramienta tiene su bloque `<toolspecific>`, que por diseño nadie más lee.
- **Leer cuesta más que ser leído.** Escribir PNML que otra herramienta acepte es la mitad fácil, porque la sintaxis es pequeña. Leer lo que escriben las demás es donde está el trabajo: nombres en sitios inesperados, varias páginas, arcos entre arcos en las extensiones, e inscripciones que son expresiones y no números.

## Puntos clave

- **PNML es una sintaxis más una URI de tipo.** La URI es el contrato; un lector que la ignore leerá encantado una red coloreada como una red P/T.
- El analizador hace **la ida y vuelta de las 24 redes del curso** byte a byte, y `check.sh` lo comprueba en cada commit, de modo que los ficheros `.pnml` y las definiciones en C# no pueden desviarse.
- Una ida y vuelta **conserva la red y pierde el dibujo**. Es una decisión de diseño, y significa que un editor gráfico y un analizador no son intercambiables.
- **Lee un fichero que nadie de tu lado haya escrito.** Dieciséis ficheros de otra herramienta encontraron un defecto real en tres minutos; diez lecciones de salida coherente consigo misma no habían encontrado ninguno.
- El defecto era un **nombre en la `<page>` en vez del `<net>`** — de esas cosas que una norma permite, las herramientas resuelven de forma distinta y solo un fichero ajeno revela.
- Una red P/T puede escribirse en la **gramática de alto nivel** con un conjunto de colores de un solo valor, y entonces resulta ilegible para un lector P/T. La misma red, otro lenguaje.
- Las herramientas de verdad son **TINA, LoLA, CPN Tools, GreatSPN, TAPAAL, Snoopy, PIPE, ePNK y ProM**. El analizador de este curso no es una de ellas y no pretende serlo.

## Ejercicios

1. Toma `nets/queue-5.pnml`, cambia la URI de `type` por la de las redes simétricas y predice qué hace el lector antes de ejecutarlo.
2. La ida y vuelta pierde los `<graphics>`. Di qué habría que cambiar en `PetriNet` para conservarlos, y si tú lo harías.
3. Escribe a mano el fichero PNML más pequeño que el lector acepta, y di qué elementos omitiste y por qué eso es legal.
4. El analizador aplana varias `<page>` en una. Nombra una red para la que eso pierda información que importa, y otra para la que no.

<details>
<summary>Soluciones</summary>

**1.** Lanza `NotSupportedException` con el mensaje `Net type symmetricnet is not the P/T net type ptnet.` — y ese es exactamente el comportamiento que fija una prueba unitaria de `PnmlTests`, haciendo esa sustitución sobre la red `handshake`. El fichero sigue siendo PNML válido y sigue analizándose como XML; solo el lector lo rechaza. Fíjate en lo que pasaría sin esa comprobación: las plazas de una red simétrica llevan una declaración de conjunto de colores y sus arcos llevan expresiones en vez de enteros, así que el análisis fallaría más tarde, en `int.Parse`, con un mensaje sobre una cadena que no es un número — un error peor sobre un problema real.

**2.** `Place` y `Transition` necesitarían una posición, `Arc` una lista de puntos intermedios, y cada nombre un desplazamiento; el escritor los emitiría y el lector los conservaría. Serán unas cuarenta líneas.

Yo no lo haría. El analizador no dibuja nunca nada — la [lección 1](../01-why-petri-nets/) le confía el dibujo a Mermaid, que coloca el grafo por su cuenta — así que las coordenadas se arrastrarían por todo el programa sin que nadie las leyera. El sitio adecuado para esos datos es una herramienta cuyo oficio sea el dibujo, y lo adecuado para esta es decir con claridad que los tira.

**3.** Una red con una plaza, una transición y un arco, sin nombres, sin marcado, sin inscripción:

```xml
<pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
  <net id="n" type="http://www.pnml.org/version-2009/grammar/ptnet">
    <page id="p">
      <place id="p1"/>
      <transition id="t1"/>
      <arc id="a1" source="p1" target="t1"/>
    </page>
  </net>
</pnml>
```

Los nombres se omiten porque un identificador es obligatorio y un nombre no, así que el lector recurre al identificador — que es lo que le pasó a `t1` en el ejemplo de la ISO. El marcado se omite porque ausente significa cero, y la inscripción porque ausente significa uno. Lo que no se puede omitir es el atributo `type`, los identificadores, y el `source` y el `target` del arco: eso es la red.

**4.** Importa para una red cuyas páginas son una *descomposición* — una página por subsistema, unidas por nodos de referencia, que es como un modelo industrial grande sigue siendo legible. Aplanarla conserva las matemáticas y destruye la única estructura por la que un humano podía orientarse. No importa para una red cuyas páginas son paginación: la misma red plana repartida en dos hojas para imprimirla. El analizador no sabe distinguirlas, que es el argumento para decir que aplana en vez de fingir que preserva.

</details>

## Fuentes

- [PNML](https://www.pnml.org/), la web del formato, con las [gramáticas RELAX NG](http://www.pnml.org/version-2009/grammar/pnmlcoremodel.rng) libres del modelo básico.
- [ISO/IEC 15909-2:2011](https://www.iso.org/standard/43538.html), *Systems and software engineering — High-level Petri nets — Part 2: Transfer format*, con la [parte 1](https://www.iso.org/standard/67235.html) para los conceptos y la [parte 3](https://www.iso.org/standard/81504.html) para las extensiones. Los registros se comprobaron en iso.org; las normas son de pago y no las he leído. *Por verificar.*
- Hillah, Kordon, Petrucci y Trèves, «PNML Framework: An Extendable Reference Implementation of the Petri Net Markup Language», en *Applications and Theory of Petri Nets 2010*, Springer LNCS 6128, [doi:10.1007/978-3-642-13675-7_20](https://doi.org/10.1007/978-3-642-13675-7_20). Registro confirmado vía Crossref; no leído. *Por verificar.*
- [ePNK](http://www2.imm.dtu.dk/~eki/projects/ePNK/), cuyo [paquete de ejemplos](http://www2.imm.dtu.dk/~eki/projects/ePNK/downloads/ePNK-1.0.0-examples.zip) aportó los dieciséis ficheros ajenos, bajo [EPL-1.0](https://www.eclipse.org/legal/epl-v10.html).
- El [Model Checking Contest](https://mcc.lip6.fr/), que ejecuta estas herramientas unas contra otras cada año sobre una colección pública en PNML.
- La implementación que imprime esta lección: [`Pnml.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Pnml.cs), con el lector, el escritor y las pruebas, incluida la que lleva la forma incómoda del ejemplo de la ISO.
