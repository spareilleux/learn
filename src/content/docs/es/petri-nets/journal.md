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
- [ ] Lección 5 — Invariantes
- [ ] Lección 6 — Clases estructurales
- [ ] Lección 7 — Modelar la concurrencia
- [ ] Lección 8 — Redes coloreadas
- [ ] Lección 9 — Tiempo y probabilidad
- [ ] Lección 10 — Flujos de trabajo
- [ ] Lección 11 — Herramientas e interoperabilidad
- [ ] Lección 12 — Aplicaciones industriales
- [ ] Lección 13 — Frente a otros formalismos
- [ ] Lección 14 — Sobre nuestros propios sistemas
- [ ] Lección 15 — Límites y qué viene después

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
