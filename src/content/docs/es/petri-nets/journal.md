---
title: Diario
description: Notas fechadas del curso de redes de Petri — el diseño del analizador, un PNML que mentía sobre su codificación, un árbol de cobertura impreso en el orden equivocado, los números de Lucas apareciendo sin invitación, y lo que no he podido verificar.
sidebar:
  order: 99
---

## Progreso

- [x] Lección 1 — Por qué las redes de Petri
- [x] Lección 2 — La definición formal y la matriz de incidencia
- [x] Lección 3 — El grafo de alcanzabilidad
- [x] Lección 4 — Propiedades
- [x] Lección 5 — Invariantes
- [x] Lección 6 — Clases estructurales
- [x] Lección 7 — Modelar la concurrencia
- [x] Lección 8 — Redes coloreadas
- [ ] Lección 9 — Tiempo y probabilidad
- [ ] Lección 10 — Flujos de trabajo
- [ ] Lección 11 — Herramientas e interoperabilidad
- [ ] Lección 12 — Aplicaciones industriales
- [ ] Lección 13 — Frente a otros formalismos
- [ ] Lección 14 — Sobre nuestros propios sistemas
- [ ] Lección 15 — Límites y qué viene después

## QA

Este curso enseña un formalismo y se ejecuta sobre un analizador que escribí yo, así que no hay ningún producto de terceros contra el que abrir incidencias. Lo que la tabla contiene en su lugar es lo que encontró el recalcular: dos defectos en el analizador, y toda afirmación que resultó estar mal cuando se le preguntó al programa. Los números de línea apuntan a los archivos de [`code/petri-nets`](https://github.com/spareilleux/learn/tree/main/code/petri-nets).

| Esperado | Lo que pasa | Dónde | Medición | Estado |
|---|---|---|---|---|
| La declaración del PNML indica la codificación que el archivo tiene | `XmlWriter.Create(StringBuilder, settings)` escribe `encoding="utf-16"` diga lo que diga `XmlWriterSettings.Encoding`, porque la codificación viene del `TextWriter`; los bytes eran UTF-8 | [`Pnml.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Pnml.cs) | Los ocho archivos del lote 1 declaraban una codificación que no tenían | Arreglado con una subclase de `StringWriter` de tres líneas que redefine `Encoding` (2026-09-15) |
| El árbol de cobertura se imprime como un árbol | El primer impresor recorría los nodos en orden de creación y los indentaba por profundidad, así que los hijos aparecían bajo hermanos sin relación | [`Report.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Report.cs), `Tree` | El árbol de 17 nodos de `unbounded-producer` se leía como un sinsentido; estuve a punto de escribir una lección alrededor | Arreglado: el impresor recorre el árbol en profundidad desde la raíz (2026-09-15) |
| El marcado más lejano del productor/consumidor está a 6 disparos de *M0* | Está a 8 | Borrador de la lección 3 | `PathTo(11)` devuelve ocho nombres de transición | Corregido antes de publicar (2026-09-15) |
| `handshake` tiene 8 marcados alcanzables | Tiene 1, y ese está muerto | Borrador de la lección 2 | `ReachabilityGraph.Build` devuelve un único estado | Corregido antes de publicar (2026-09-15) |
| Una **trampa** sin marcas es lo que hace espuria a una solución | Es un **sifón**. Una trampa que está marcada sigue marcada; un sifón que está vacío se queda vacío | Borrador de la lección 2 | Las dos definiciones son duales y el borrador las tenía al revés | Corregido antes de publicar (2026-09-15) |
| `handshake` tiene el invariante de transiciones (1, 1) | No tiene **ninguno**: `receive` deja caer una marca en `served` que nada retira, así que ningún multiconjunto de disparos se cancela | [`Invariants.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Invariants.cs) | `Invariants.Transitions(handshake).Count` es 0, y también para `handshake-started` | Corregido antes de publicar; la lección 5 usa ahora ese cero como resultado propio (2026-09-17) |
| `mutual-exclusion` queda fuera de la clase de elección asimétrica | Queda **dentro**: `idle1•` e `idle2•` están cada uno contenidos en `mutex•` | [`Structure.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Structure.cs) | Una prueba unitaria que afirmaba lo contrario falló; los filósofos son la red que sí cae fuera de la clase | Prueba corregida a la respuesta medida (2026-09-17) |
| `{x, y}` sigue siendo un sifón minimal cuando los dos hilos toman `x` primero | Ya no es minimal: `{y}` sola pasa a ser un sifón, y `x` queda en `{a_has_x, b_has_x, x}` | Lección 6, ejercicio 1 | `two-locks-ordered` tiene 4 sifones minimales, todos con una trampa marcada | Corregido antes de publicar, y la predicción equivocada se publica junto a la respuesta correcta (2026-09-17) |
| El sifón sin trampa de un cerrojo que nunca se suelta es `{critical1, critical2, mutex}` | Hay dos, `{idle1}` y `{critical2, mutex}`; `{critical1}` resulta ser una trampa | Lección 7, ejercicio 2 | `Report.Siphons(mutual-exclusion-leaky)` | Corregido antes de publicar (2026-09-17) |

## Experimentos

Una advertencia antes de la tabla: a diferencia del [laboratorio GA](../../ga-lab/journal/), este curso no commitea sus hipótesis a un archivo antes de medir. Las predicciones de abajo se escribieron en mis notas mientras construía cada red y luego se contrastaron con el programa; esa disciplina es más débil, y donde una predicción falló fue el analizador quien lo detectó, no un revisor.

| Pregunta | Hipótesis, escrita antes de medir | Resultado | Veredicto |
|---|---|---|---|
| ¿Dan los invariantes de plazas las mismas cotas que el grafo de alcanzabilidad? | Dan los mismos seis números sobre el productor y el consumidor | Idénticos, plaza por plaza, y ahora una prueba unitaria falla si divergen: 0 marcados enumerados de un lado, 12 del otro | Confirmada (2026-09-17) |
| ¿La plaza que crece no tiene invariante? | Quitar `free` quita el invariante que acotaba `full` | `unbounded-producer` tiene 2 invariantes de plazas en vez de 3, y a `full` no lo cubre ninguno | Confirmada, con la salvedad que enuncia la lección: no estar cubierta es una prueba que falta, no una prueba de no acotación (2026-09-17) |
| ¿Pueden los invariantes de plazas excluir una solución espuria? | No — son consecuencias de la ecuación de estado | Las dos soluciones espurias de `handshake`, (0, 0, 1) y (0, 0, 2), satisfacen todos los invariantes de plazas | Confirmada (2026-09-17) |
| ¿Coincide la condición de Commoner con el grafo de alcanzabilidad? | En todas las redes de libre elección del curso | Coincidencia en las cuatro — `producer-consumer` viva, `start-once` y `handshake` no, `connection` viva — y una prueba unitaria lo afirma | Confirmada, solo sobre cuatro redes; el teorema en sí está tomado de fuentes secundarias (2026-09-17) |
| ¿Son los circuitos de un grafo marcado los mismos conjuntos que sus invariantes de plazas? | Sí, con las mismas constantes | Los tres circuitos de `producer-consumer` son `{ready, produced}` 1, `{free, full}` 2, `{waiting, taken}` 1 — los tres invariantes de la lección 5 | Confirmada (2026-09-17) |
| ¿Cuántos invariantes de transiciones tiene la red `handshake`? | (1, 1): `receive` y luego `reply` devuelve la marca | **Cero**, y el prefijo de 500 marcados de `handshake-started` no contiene ningún marcado alcanzable dos veces | Refutada, y se convirtió en el mejor resultado: una red sin T-invariante nunca puede volver a un marcado que haya dejado (2026-09-17) |
| ¿Cuánto cuesta tomar los tenedores de uno en uno? | Un interbloqueo, y más marcados | Exactamente **un** marcado muerto a cada tamaño de 2 a 6 filósofos, y 6, 14, 34, 82, 198 marcados frente a 3, 4, 7, 11, 18 de la versión atómica | Confirmada, y la constante 1 fue una sorpresa (2026-09-17) |
| ¿Qué le hace a la estructura invertir un filósofo? | Quita el interbloqueo | Quita un **sifón**: tres filósofos tienen 7 sifones minimales, uno de ellos — `{eating1, fork1, eating2, fork2, eating3, fork3}` — sin trampa marcada; invertido, 6 sifones y ninguno sin ella | Confirmada, y es el enunciado estructural de «ordena tus cerrojos» (2026-09-17) |
| ¿Está una transición viva a salvo de la inanición? | No | `start_write` es L4 en lectores y escritores, y el grafo contiene un ciclo de dos marcados, `start_read` y luego `stop_read`, que no la dispara nunca | Confirmada: la vivacidad es «siempre posible», nunca «acaba ocurriendo» (2026-09-17) |
| ¿Encoge el color el espacio de estados? | No — solo pliega el modelo | 4 plazas y 4 transiciones a cualquier límite de intentos; el despliegue y el número de marcados alcanzables crecen los dos linealmente, 8, 10, 14, 24, 44 marcados para los límites 2, 3, 5, 10, 20 | Confirmada, y es el argumento central de la lección 8 (2026-09-17) |

## 2026-09-15 — Lecciones 1 a 4, y el analizador sobre el que se ejecutan

**Por qué escribir un analizador.** Existen herramientas maduras — TINA, LoLA, CPN Tools, GreatSPN, TAPAAL — y la lección 11 las usará. Aun así escribí uno pequeño, por tres razones. Un curso cuyas salidas compara la CI necesita un programa cuya salida yo controle hasta el orden. Un lector que tiene la regla de disparo delante en C# la entiende más rápido que uno que tiene una captura de pantalla de una interfaz gráfica. Y el analizador es la única forma honesta de escribir estas lecciones: los doce marcados, los diecisiete nodos del árbol y las dos soluciones espurias los imprime él, no los recuerdo yo.

Son unas 1 400 líneas repartidas en diez archivos de [`code/petri-nets/PetriNets`](https://github.com/spareilleux/learn/tree/main/code/petri-nets/PetriNets): la red y la regla de disparo, PNML de lectura y de escritura, el grafo de alcanzabilidad, el árbol de cobertura de Karp–Miller, los invariantes de plazas y de transiciones por eliminación de Farkas, la ecuación de estado y un impresor. El SDK de .NET de esta máquina es el 10.0.112, sobre .NET 10.0.12; `global.json` fija la banda 10.0.1xx con `rollForward: latestFeature`, de modo que la versión preliminar 11.0.100, también instalada, no se elige.

**El determinismo fue la restricción que dio forma al código.** Todo lo que una lección cita tiene que salir igual en Windows, Linux y macOS, y las colecciones basadas en hash no lo prometen. Por eso el grafo de alcanzabilidad se construye en anchura y numera sus estados en orden de descubrimiento; los disparos se ordenan por estado origen y luego por transición antes de devolverlos; los invariantes se normalizan por su máximo común divisor y se ordenan; el escritor de PNML emite finales de línea LF y una indentación fija. `check.sh` compara cuatro salidas de lección y ocho archivos PNML, así que un cambio que reordene algo falla de inmediato en vez de dejar una lección equivocada en silencio.

**Sorpresas:**

- **El búfer sin freno está a una plaza de distancia.** Quitar `free` y sus dos arcos del productor/consumidor convierte una red de doce marcados en una cuyo conjunto alcanzable es infinito. Nada en la imagen avisa; lo hace la *ausencia* de una plaza. Ahora leo «qué plaza detiene esta transición» como la primera pregunta que hacerle a una red.
- **Los números de Lucas.** El grafo de alcanzabilidad de *n* filósofos tiene 3, 4, 7, 11, 18, 29, 47, 76, 123 marcados para *n* = 2 … 10. Esperaba algo como 2ⁿ y obtuve una sucesión donde cada término es la suma de los dos anteriores. Tiene sentido en cuanto ves que un marcado es una elección de qué filósofos comen, sin que dos sean vecinos — los conjuntos independientes de un ciclo, contados por los números de Lucas. Un recordatorio agradable de que el espacio de estados tiene estructura, que es justo lo que explotan las técnicas de reducción de la lección 15.
- **El árbol de cobertura es mayor que el grafo al que sustituye.** Para el productor/consumidor acotado: 56 nodos de árbol para 12 marcados. Un árbol no comparte nada, así que cada marcado se repite una vez por cada camino que llega a él. El árbol solo sale a cuenta cuando el grafo no existe en absoluto.
- **Las soluciones espurias son más difíciles de construir que de describir.** Quería un marcado que satisficiera *M* = *M0* + *C x* sin ser alcanzable, y mis cuatro primeros intentos fallaron por la misma razón: en esas redes todo ciclo llevaba una marca, así que la ecuación de estado y la regla de disparo coincidían. La que funciona es la red `handshake`, donde `receive` y `reply` se pasan una sola marca y nadie envía nunca la primera petición — la ecuación deja que `receive` tome prestada la marca que `reply` solo produciría después. En vez de fiarme de la construcción, el analizador ahora enumera todos los marcados hasta un presupuesto de marcas e informa de los que la ecuación acepta y el grafo no contiene; encuentra `(0, 0, 1)` y `(0, 0, 2)`. Una prueba comprueba además lo contrario para el productor/consumidor, que no tiene ninguna.

**Dos errores míos, los dos de impresión más que de matemáticas:**

- **Un PNML que mentía sobre su codificación.** `XmlWriter.Create(StringBuilder, settings)` escribe `encoding="utf-16"` en la declaración diga lo que diga `XmlWriterSettings.Encoding`, porque la codificación se toma del `TextWriter`. Los archivos se escribían en UTF-8, así que cada uno declaraba una codificación que no tenía — inofensivo para mi propio lector, una trampa para cualquier herramienta que crea la declaración. Arreglado con una subclase de `StringWriter` de tres líneas que redefine `Encoding`.
- **Un árbol de cobertura impreso en el orden equivocado.** La primera versión imprimía los nodos en orden de creación y los indentaba por profundidad, lo que parece un árbol sin serlo: los hijos de un nodo creado más tarde aparecían bajo un hermano sin relación. La salida no tenía sentido y estuve a punto de escribir una lección alrededor. El impresor ahora recorre el árbol en profundidad desde la raíz.

**Lo que no he podido verificar, y he marcado como tal:**

- El artículo de síntesis de Murata está tras el muro de pago de la IEEE, e IEEE Xplore rechazó la petición sin más. El registro bibliográfico está confirmado a través de Crossref — *Proceedings of the IEEE* 77(4), abril de 1989, páginas 541–580, [doi:10.1109/5.24143](https://doi.org/10.1109/5.24143) — y las definiciones que le atribuyo son las estándar, pero no he leído el artículo en sí. Donde tendría que apoyarme en él para una afirmación que no puedo comprobar de otro modo — que la ecuación de estado es necesaria *y suficiente* para las redes acíclicas — la lección 2 dice *por verificar* en lugar de afirmarlo.
- El informe técnico de Yale de Lipton, 1976, para la cota inferior EXPSPACE de la cobertura, está citado a partir de fuentes secundarias. La cota superior correspondiente de Rackoff sí está confirmada: *Theoretical Computer Science* 6(2), 1978, páginas 223–231.
- Todo lo relativo a la complejidad de la alcanzabilidad está anclado a artículos cuyos registros comprobé en Crossref: decidibilidad por Mayr (STOC 1981) y Kosaraju (STOC 1982), cota superior ackermanniana por Leroux y Schmitz (LICS 2019), y cota inferior correspondiente por Czerwiński y Orlikowski y, de forma independiente, Leroux, ambos en FOCS 2021. Quería el estado *actual* de esa cuestión en vez del «decidible, complejidad abierta» de los manuales más antiguos, y 2021 la cerró.
- ISO/IEC 15909 tiene tres partes, y las comprobé las tres en iso.org: la parte 1 (2019, conceptos), la parte 2 (2011, el formato de intercambio que escribe este curso, confirmada por última vez en 2024) y la parte 3 (2021, extensiones). La norma en sí cuesta 227 CHF y no la he leído; el PNML que escribe el analizador sigue la gramática pública de [pnml.org](https://www.pnml.org/) y da la vuelta completa por su propio lector, que es todo lo que este curso afirma.

**Queda por hacer:**

- El flujo de trabajo de CI `.github/workflows/petri-nets-examples.yml` está escrito pero **no confirmado**: el token disponible aquí no tiene el alcance `workflow`. Nada en las lecciones afirma tener una CI en verde mientras no se haya ejecutado.
- El dogfooding de la lección 14 — una tubería `Channel<T>` de Guitar Alchemist, una topología de RabbitMQ, una actualización progresiva de Kubernetes, una tubería de agentes — no ha empezado. El lote 1 solo modela sistemas de manual, y lo dice.

## 2026-09-15 — Traducciones

Las versiones francesa y española de la misión, de las lecciones 1 a 4 y de este diario se produjeron a partir del commit en inglés, copiando los bloques de código con un script y traduciendo solo la prosa, los comentarios del código y las etiquetas de Mermaid. Los nombres de las plazas y de las transiciones dentro de las redes forman parte de la salida del programa: se quedan en inglés en los tres idiomas, porque traducirlos haría que los listados dejaran de coincidir con `expected/`.

## 2026-09-17 — Lecciones 5 a 8, y las cuatro cosas que el analizador me dijo que tenía mal

La cuestión de la CI del lote 1 está zanjada: `.github/workflows/petri-nets-examples.yml` se commiteó y está en verde en Ubuntu, Windows y macOS desde el 2026-09-16, en `53ceefc`. Ahora ejecuta ocho lecciones en vez de cuatro.

**Lo que creció el analizador.** 672 líneas en tres archivos nuevos, más añadidos a cuatro existentes:

- [`Structure.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Structure.cs) — las clases (máquina de estados, grafo marcado, libre elección, libre elección extendida, elección asimétrica, ordinaria, pura, fuertemente conexa), los circuitos elementales, los sifones y las trampas por fuerza bruta sobre los subconjuntos de plazas, y la mayor trampa dentro de un conjunto por el punto fijo de siempre.
- [`Coloured.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Coloured.cs) — conjuntos de colores, guardas, expresiones de arco, una regla de disparo sobre marcados coloreados, y `Unfold()` hacia una red P/T ordinaria.
- En [`Invariants.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Invariants.cs), la cota que cada plaza obtiene solo de los invariantes, y el rango de *C* por eliminación entera exacta.
- En [`ReachabilityGraph.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/ReachabilityGraph.cs), `CycleAvoiding(t)`: un ciclo alcanzable desde *M0* que nunca dispara *t*. Dos docenas de líneas, y es lo que convierte «esta transición es viva» en «y aquí está la ejecución en la que no ocurre nunca».

Se añadieron siete redes a las que exporta el lote 1 — `connection`, `handshake-started`, `readers-writers`, `counting-semaphore`, los filósofos tomando un tenedor cada vez con y sin un orden impuesto, y el despliegue de la red coloreada de reintentos — y una octava, el cerrojo que nunca se suelta, existe solo para romperse en el ejercicio de la lección 7 y no se exporta. Toda red exportada se regenera y se compara con `check.sh`. Las pruebas unitarias pasaron de 30 a 52.

**El resultado que no esperaba, y que me quedé.** La lección 5 iba a terminar en «existe un invariante de transiciones pero no puede dispararse», con la red `handshake` como ejemplo. La red `handshake` no tiene ningún invariante de transiciones. `receive` mete una marca en `served` y nada la saca nunca, así que ningún multiconjunto no vacío de disparos se cancela; y en cuanto eso es cierto, la red nunca puede volver a un marcado que haya dejado. La lección dice ahora eso, que es un hecho mejor, y `two-locks` lleva el argumento original — tiene dos T-invariantes y un marcado desde el que ninguno puede empezar.

**Otras tres predicciones que el programa rechazó**, todas en la tabla de QA de arriba: `mutual-exclusion` *sí* es una red de elección asimétrica (una prueba unitaria que afirmaba lo contrario falló), `{x, y}` deja de ser un sifón minimal en cuanto los dos hilos toman `x` primero, y el cerrojo que nunca se suelta tiene dos sifones sin trampa en vez del único que yo nombré. La lección 6 publica la predicción equivocada junto a la respuesta correcta, porque la forma del error — suponer que un conjunto sigue siendo minimal cuando la estructura a su alrededor cambia — es más útil que la respuesta.

**Sorpresas que merece la pena conservar:**

- **Los filósofos se interbloquean exactamente una vez.** De dos a seis filósofos, un tenedor cada vez: 1 marcado muerto siempre, de 6, 14, 34, 82, 198. Esperaba que el número creciera con el anillo. No crece, porque la única forma de perder es que *todo el mundo* tenga un tenedor, y hay un solo marcado así.
- **La inanición mide dos marcados.** La red de lectores y escritores es viva, y la ejecución en la que el escritor nunca entra es `start_read`, `stop_read`, repetido. Encontrarla costó una búsqueda en profundidad sobre el grafo con una transición borrada, y verla impresa hizo concreta la diferencia entre vivacidad y equidad de una forma que las definiciones nunca lograron.
- **El color no compra nada en el análisis.** La red de reintentos conserva cuatro plazas y cuatro transiciones tanto si el límite de intentos es 2 como si es 20; el despliegue pasa de 8 plazas a 44 y los marcados alcanzables de 8 a 44. Sabía que la teoría decía esto; ver las columnas de la izquierda quietas mientras las de la derecha trepan es lo que lo hace calar.
- **La condición de Commoner se gana el sueldo en `handshake-started`.** El grafo de alcanzabilidad de esa red es infinito — el analizador se rinde a los 500 marcados — y el árbol de cobertura solo puede informar de que no está acotada y de que ninguna transición está muerta. La condición de sifones y trampas responde *viva* de todos modos, en lo que se tarda en enumerar los subconjuntos de tres plazas. Es el primer sitio de este curso donde el método estructural hace algo que la enumeración no puede hacer en absoluto.

**Lo que no he podido verificar, y he marcado como tal:**

- **Hack 1972** es donde está enunciado el teorema de vivacidad de Commoner para las redes de libre elección. El registro está confirmado en DSpace@MIT — *Analysis of production schemata by Petri nets*, MIT-LCS-TR-094, febrero de 1972, [handle 1721.1/149406](https://dspace.mit.edu/handle/1721.1/149406) — y el PDF es de acceso abierto, pero la descarga está tras una comprobación antibots que rechazó todas mis peticiones, así que **no lo he leído**. La redacción del teorema en la lección 6 viene de fuentes secundarias. Lo que la lección afirma con su propia evidencia es más estrecho y está comprobado: la condición y el grafo de alcanzabilidad coinciden en las cuatro redes de libre elección de este curso, y una prueba unitaria falla si dejan de coincidir.
- **Commoner, Holt, Even y Pnueli 1971** para los teoremas de los grafos marcados: registro confirmado a través de Crossref (*JCSS* 5(5), páginas 511–523, [doi:10.1016/S0022-0000(71)80013-2](https://doi.org/10.1016/S0022-0000(71)80013-2)), artículo tras el muro de pago de Elsevier, no leído.
- **Desel y Esparza 1995**, *Free Choice Petri Nets*: registro confirmado en Cambridge Core, [doi:10.1017/CBO9780511526558](https://doi.org/10.1017/CBO9780511526558), no leído.
- **Jensen y Kristensen 2009** para las redes coloreadas: registro confirmado a través de Crossref, [doi:10.1007/b95112](https://doi.org/10.1007/b95112), no leído. ISO/IEC 15909-1:2019, donde se define la subclase de las redes simétricas, sigue costando 227 CHF y sigue sin leerse.
- **Dijkstra 1971** para los filósofos y el orden de los recursos: registro confirmado a través de Crossref, [doi:10.1007/BF00289519](https://doi.org/10.1007/BF00289519), no leído.
- El ejercicio 3 de la lección 7 — los filósofos con un tiempo de espera — está argumentado, no construido. Está marcado *por verificar* en la propia lección.

**Una cosa que es honestamente más débil de lo que parece.** Toda afirmación de «ningún marcado enumerado» de las lecciones 5 y 6 es cierta del *método*, y el mismo programa construye luego el grafo de alcanzabilidad de todas formas para comprobar el método. Ese es el orden correcto para un curso, y significa que ninguna de estas lecciones demuestra el método sobre una red donde la enumeración fallaría de verdad — salvo `handshake-started`, que es la única red de aquí cuyo grafo no existe.

## 2026-09-21 — Primer oráculo ejecutable del ciclo de vida C#

La lección 14 conecta ahora el modelo formal con las formas de fallo medidas en las lecciones 6 y 9 de C# avanzado. Añadí un pipeline finito de una plaza con lugares explícitos `succeeded`, `failed` y `cancelled`. Su grafo completo tiene ocho marcados y tres marcados muertos; todos son terminales intencionales, así que no hay marcados muertos no terminales. Cinco pruebas enfocadas preservan esa clasificación y el invariante de capacidad `free + queued = 1`, y el fixture PNML se regenera con el resto del curso.

La corrección importante fue semántica: `DeadStates` significa que ninguna transición está habilitada, por lo que el final correcto de un workflow finito también está muerto. «Sin interbloqueo» es el oráculo equivocado para un pipeline que termina. El contrato ejecutable es, en cambio, un grafo completo cuyos marcados muertos contienen exactamente una marca terminal con nombre. La página también etiqueta honestamente los ejemplos Channel con forma de GA como reproducciones del mecanismo, no como pruebas de regresión de los binarios actuales. RabbitMQ, Redis y Kubernetes siguen siendo experimentos posteriores.

## Por verificar

- Hack 1972, la fuente del teorema de Commoner, es de acceso abierto e ilegible para una descarga automatizada. Leerlo en un navegador permitiría que la lección 6 citara el teorema en vez de parafrasear una paráfrasis.
- Murata 1989 sigue tras muro de pago y sin leer; toda atribución a él en las lecciones 1 a 8 está marcada en la página.
- Lección 7, ejercicio 3: construir los filósofos con un tiempo de espera y comprobar que la red está libre de interbloqueo y tiene una ejecución infinita en la que nadie come.
- La afirmación de que la enumeración de sifones minimales es NP-difícil se enuncia en la lección 6 a partir de conocimiento general y no está anclada a ningún artículo.

## Preguntas abiertas

- La fuerza bruta sobre los subconjuntos de plazas limita el analizador a veinte plazas. Seis filósofos tomando un tenedor cada vez tienen veinticuatro, así que el veredicto estructural no se puede calcular para la mayor red de la propia tabla de la lección 7. Una formulación con un resolutor de restricciones lo arreglaría y haría que el curso dependiera de un resolutor.
- Las redes coloreadas de la lección 8 enlazan una variable por transición. Una transición que une dos mensajes necesita una tupla, y el despliegue crecería como un producto. Si implementarlo en la lección 12, donde aparece un protocolo real, o entregarle ese modelo a CPN Tools y decirlo, está sin decidir.
- La lección 9 necesita el tiempo, y el tiempo es donde una red deja de tener una única semántica aceptada. Cuál de los formalismos temporizados — las redes de Petri temporales en el sentido de Merlin, las redes temporizadas en el sentido de Ramchandani, o las estocásticas — enseña primero este curso no está zanjado.
