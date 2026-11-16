---
title: Un catálogo de capacidades no es un grafo de colaboración
description: Ciencia de redes para ecosistemas de IA — Ciencia de redes
sidebar:
  label: NET-002 · Un catálogo de capacidades no es un grafo de colaboración
  order: 2
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/network-science/es/net-002-capability-graphs-and-projections.es.md
---

:::note[Streeling University]
**NET-002** · Ciencia de redes para ecosistemas de IA · early-intermediate · 30 minutos

Generado por el departamento *Ciencia de redes* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/network-science/es/net-002-capability-graphs-and-projections.es.md) · [Mi diario](../../journal/)

Requisitos previos: [NET-001](../../network-science/net-001-scale-free-tool-networks/)
:::

> **Alcance de la fuente y la transferencia.** El texto técnico siguiente procede de un borrador archivado. Las menciones históricas de una importación o compilación pendiente en Learn corresponden a aquella etapa; este [registro de transferencia](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/agentic-composition-2026-10-22/README.md) documenta la importación actual y sus comprobaciones. Las demás experiencias indicadas como no realizadas siguen pendientes. Aún faltan la revisión humana del contenido y del idioma, y la prueba con un estudiante.

> **Departamento de Ciencia de Redes** | Nivel: intermedio inicial | Duración estimada: 30 minutos | Estado: borrador en español; revisión y publicación pendientes

## Objetivos

Después de esta lección, podrás:

- Construir un grafo con dos tipos de nodos a partir del catálogo declarado de Demerzel que relaciona repositorios con familias de herramientas.
- Proyectar ese grafo sobre los repositorios mediante una regla de aristas explícita y contar sus componentes.
- Explicar por qué una arista de catálogo, una dependencia contractual y una llamada observada a una herramienta constituyen pruebas diferentes.
- Probar el efecto de eliminar una etiqueta sin presentarlo como una caída real de un servicio.

## La pregunta del proyecto

Un coordinador quiere reunir el análisis de acordes de GA y la ponderación gramatical de TARS en un flujo de trabajo. El [registro de capacidades](https://github.com/GuitarAlchemist/Demerzel/blob/5c4967454ddc740ed937c87719ca4d71a3522e4b/schemas/capability-registry.json) de Demerzel nombra herramientas de ambos repositorios. ¿Demuestra ese catálogo que las dos herramientas pueden invocarse en secuencia mediante una transferencia funcional entre repositorios? **No.** Es un índice de descubrimiento. Podemos representar sus etiquetas declaradas en un grafo y estudiar dónde se solapan las descripciones, pero el grafo no codifica un contrato de API, credenciales, una invocación satisfactoria ni la presencia actual de los servicios.

Esta lección utiliza únicamente el registro en el commit de Demerzel `5c4967454ddc740ed937c87719ca4d71a3522e4b` (versión del registro `1.1.0`) y la [nota sobre contratos entre repositorios](https://github.com/GuitarAlchemist/Demerzel/blob/5c4967454ddc740ed937c87719ca4d71a3522e4b/docs/architecture/cross-repo-contracts.md) en la misma revisión. Las cifras siguientes se recalcularon a partir del JSON fijado. [NET-001](../../network-science/net-001-scale-free-tool-networks/) presenta el grado, los hubs y los límites de afirmar que una red es libre de escala. Aquí la tarea es diferente: **elegir qué significa una arista antes de contarla**. No se consultó ningún endpoint MCP activo para esta lección.

## 1. Construir el grafo declarado con dos tipos de nodos

Abre el objeto JSON `repos`. Sus tres claves de repositorio son `ix`, `tars` y `ga`. En cada uno, `tools` relaciona **nombres de familias** con listas de herramientas con nombre. Construye un grafo no dirigido con dos tipos de nodos: uno representa un repositorio y el otro una cadena exacta de nombre de familia. Traza una arista desde el repositorio `r` hasta la familia `f` cuando `f` sea una clave de `repos[r].tools`. Se cuentan *familias*, no nombres de herramientas individuales. Por ejemplo, `ix` tiene una arista hacia `grammar`, aunque esa familia enumera tres herramientas `ix_grammar_*`. `tars` también tiene una arista hacia `grammar`, donde las herramientas enumeradas tienen otros nombres. La etiqueta común demuestra una palabra compartida en el catálogo, no que las implementaciones acepten las mismas entradas.

| Nodo de repositorio | Grado declarado por familias | Un ejemplo comprobado |
|---|---:|---|
| `ix` | 27 | `grammar` contiene `ix_grammar_weights`, `ix_grammar_evolve` e `ix_grammar_search` |
| `tars` | 4 | `grammar` contiene `tars_grammar_weight` y `tars_grammar_evolve` |
| `ga` | 5 | `music-theory` contiene `ga_scale`, `ga_chord`, `ga_chord_atonal` y `ga_interval` |

La suma de grados del lado de los repositorios es `27 + 4 + 5 = 36`, así que esta definición produce **36 aristas entre repositorios y familias**. Hay **35 nodos de nombres de familia distintos**, porque `grammar` es la única clave de familia repetida; todas las demás aparecen en uno solo de los tres repositorios. Por tanto, el grafo tiene `3 + 35 = 38` nodos. Este cálculo corresponde al registro fijado; una revisión posterior puede añadir, renombrar o eliminar declaraciones. También es un grafo deliberadamente limitado. No incluye a Demerzel como nodo de repositorio por el mero hecho de que Demerzel almacene el registro.

### Ejercicio práctico 1: contar la unidad correcta

Un compañero afirma que «`ix` tiene tres aristas de gramática» porque se enumeran tres herramientas gramaticales. Según la regla de esta lección, ¿cuál es el grado de `ix`, cuánto aporta la gramática y cuántos nodos y aristas tiene el grafo completo con dos tipos?

> **Respuesta:** `ix` tiene grado 27: una arista por clave de familia de `tools`, con exactamente una arista `ix`–`grammar`. El grafo fijado completo tiene 3 nodos de repositorios y 35 nodos de familias distintos, es decir, 38 nodos; los grados del lado de los repositorios suman 36 aristas de incidencia. Contar entradas de herramientas definiría otro grafo y otros grados.

## 2. Proyectar sobre los repositorios e interpretar la proyección con cuidado

Una **proyección sobre los repositorios** sustituye cada camino de dos pasos `repo A → family → repo B` por una arista no dirigida A–B. Formula la regla con precisión: conectar dos repositorios solo si sus objetos `tools` comparten al menos una **clave de familia idéntica**. Al examinar los conjuntos fijados se obtiene `ix ∩ tars = {grammar}`, `ix ∩ ga = ∅` y `tars ∩ ga = ∅`. Por tanto, la proyección de tres nodos tiene una arista, `ix`–`tars`. Tiene dos componentes conexas: `{ix, tars}` y `{ga}`. En el grafo original con dos tipos, esas mismas dos componentes también contienen sus nodos de familia asociados.

La proyección ha descartado información. No muestra que `ix` tenga 27 familias y `tars` 4, ni que sus implementaciones de `grammar` sean herramientas diferentes. GA aparece aislado con esta **regla de etiqueta exacta**, aunque tiene cinco familias de herramientas declaradas y puede participar en otros acuerdos entre repositorios. No cambies el nombre de la familia `spectral` de `ga` por `signal` de `ix`, ni el de `music-theory` por otra etiqueta, solo para dibujar una conexión. La similitud semántica necesita una correspondencia revisada y un caso de uso; la comparación de cadenas es reproducible precisamente porque no hace suposiciones.

### Ejercicio práctico 2: enumerar las aristas proyectadas

¿Qué pares de repositorios comparten una clave de familia exacta? Indica el número de aristas, los grados y las componentes conexas de la proyección. ¿Que `ga` esté aislado significa que su servidor MCP está caído?

> **Respuesta:** Solo `ix` y `tars` comparten `grammar`, por lo que la proyección tiene una arista. Sus grados son `ix: 1`, `tars: 1`, `ga: 0`; sus componentes son `{ix, tars}` y `{ga}`. El grado proyectado cero de `ga` solo indica que sus cinco **etiquetas** de familia no coinciden exactamente con las demás de este registro. No dice nada sobre la disponibilidad del servidor ni sobre si otro contrato conecta GA con otro repositorio.

## 3. Un corte de grafo no es un informe de incidente

Supongamos que un analista elimina el **nodo de familia `grammar` de este modelo** para ver qué etiqueta sostiene la conexión proyectada. El grafo original con dos tipos pasa a tener 34 nodos de familias y 34 aristas de incidencia: al borrar la familia compartida, se borran sus dos aristas con los repositorios. Sus grados de repositorio pasan a ser `ix: 26`, `tars: 3` y `ga: 5`. La proyección sobre los repositorios no tiene aristas y presenta tres nodos de repositorio aislados. Es un pequeño ejemplo de punto de articulación: la única palabra compartida del catálogo es el único camino de dos pasos entre `ix` y `tars` según la regla elegida.

Es un resultado de sensibilidad sobre una **taxonomía estática**. No simula detener un servidor MCP ni demuestra que un agente pierda una capacidad gramatical funcional. Eliminar una etiqueta de un documento JSON podría significar un cambio de nombre, una limpieza del catálogo o una eliminación real; el grafo por sí solo no permite distinguirlos. Para estudiar la resiliencia operativa, define los nodos como servicios o llamadas reales, obtén aristas de dependencias observadas y prueba el modo de fallo contra esos comprobantes.

### Ejercicio práctico 3: eliminar una familia

Tras borrar el nodo de familia `grammar`, calcula los números de nodos y aristas del grafo con dos tipos y el número de componentes de la proyección sobre repositorios. ¿Qué conclusión operativa carece de respaldo?

> **Respuesta:** El grafo con dos tipos tiene `3 + 34 = 37` nodos y `36 - 2 = 34` aristas de incidencia. La proyección sobre repositorios tiene cero aristas y tres componentes, una por repositorio. Esto **no** demuestra que un servicio gramatical activo haya fallado ni que el trabajo se haya detenido; solo se ha eliminado un nodo de nombre de familia declarado del grafo analítico.

## 4. Cambiar la regla de aristas cambia la afirmación

La [nota fijada sobre contratos entre repositorios](https://github.com/GuitarAlchemist/Demerzel/blob/5c4967454ddc740ed937c87719ca4d71a3522e4b/docs/architecture/cross-repo-contracts.md) describe un grafo *distinto*. Para su punto de integración BAML, Demerzel es responsable de [`baml_src/schema.baml`](https://github.com/GuitarAlchemist/Demerzel/blob/5c4967454ddc740ed937c87719ca4d71a3522e4b/baml_src/schema.baml) y nombra a `ix`, `ga` y `hari` como consumidores previstos. Si la pregunta es «¿Quién tendría que reaccionar a un cambio del esquema BAML?», representa aristas dirigidas de **productor declarado → consumidor previsto**: `Demerzel → ix`, `Demerzel → ga` y `Demerzel → hari`. Ese grafo tiene cuatro nodos de repositorios identificados y tres aristas declaradas. No se deduce de las etiquetas `tools` compartidas. `hari` y Demerzel no aparecen en la proyección de tres repositorios del registro porque esa proyección utiliza otros datos y otra regla para los nodos.

La nota contractual señala expresamente que la generación por parte de los consumidores a partir de este contrato BAML estaba **sin entregar** en la fecha del documento fijado: ningún consumidor generaba todavía a partir de él. También advierte que sus afirmaciones de disponibilidad envejecen. Por tanto, las tres flechas son **aristas de coordinación previstas**, no tres integraciones funcionales observadas. Un diagrama de proyecto útil distingue las aristas declaradas y observadas mediante estilos de línea, fechas y comprobantes; no convierte silenciosamente una flecha de diseño en una llamada en ejecución. Tampoco la ausencia de una flecha BAML hacia `tars` demuestra que no exista ninguna otra relación con TARS: este párrafo solo trata un punto de integración concreto.

### Ejercicio práctico 4: comparar dos grafos

Dibuja el grafo BAML de productor a consumidores nombrados en la nota contractual. ¿Por qué es incorrecto sumar sus tres flechas a las 36 aristas entre repositorios y familias y llamar al total una sola red? ¿Qué flechas tienen un comprobante confirmado de generación activa en la nota fijada?

> **Respuesta:** El grafo BAML declarado tiene `Demerzel → ix`, `Demerzel → ga` y `Demerzel → hari`: cuatro nodos de repositorios y tres aristas dirigidas previstas. Las 36 aristas del catálogo unen nodos de repositorios con nodos de nombres de familias y son declaraciones no dirigidas, de modo que sumar aristas de distinta naturaleza produce un recuento sin significado estable. La nota fijada dice que la generación por parte de los consumidores no está entregada; no confirma **ninguna** flecha de generación activa de un consumidor.

## 5. Convertir el grafo en una pregunta de enrutamiento acotada

El registro enumera `ga_chord` en la familia `music-theory` de GA y `tars_grammar_weight` en la familia `grammar` de TARS. Un coordinador podría *proponer* una tarea de dos pasos: pedir a GA datos de acordes y después pedir a TARS que pondere una gramática a partir de una entrada definida explícitamente. El catálogo identifica herramientas candidatas; no especifica si sus salidas y entradas encajan. Antes de tratar la ruta como ejecutable, registra las versiones y esquemas exactos de las herramientas, la transformación entre sus datos, la autorización, la gestión de errores y una invocación de prueba satisfactoria en un momento indicado. Si falta algo, etiqueta el enlace como propuesto o desconocido. Un diagrama que recoge esa incertidumbre es más útil que una ruta visualmente completa pero sin verificar.

### Ejercicio práctico 5: hacer refutable una afirmación sobre una ruta

Un plan dice: «GA y TARS están desconectados porque la proyección del registro no tiene arista; por tanto, `ga_chord` no puede alimentar a `tars_grammar_weight`». Reformúlalo como una afirmación comprobable. ¿Qué resultado establecería solo esa ruta concreta, en lugar de una afirmación general sobre todo el ecosistema?

> **Respuesta:** «El registro fijado no contiene una arista de **etiqueta de familia compartida** entre GA y TARS. Se desconoce si la salida de `ga_chord` puede transformarse en una entrada válida de `tars_grammar_weight` hasta comprobar sus esquemas actuales y una llamada de prueba autorizada». Una correspondencia versionada de entradas y salidas más una invocación satisfactoria registrada respaldaría esa ruta concreta en las condiciones probadas. No demostraría todas las integraciones GA/TARS ni la disponibilidad permanente de los servicios.

## Ideas clave

- Nombra los tipos de nodos y la regla de aristas antes de calcular grados, caminos o componentes.
- La proyección por etiqueta exacta es reproducible, pero pierde detalles de las herramientas y no dice nada por sí sola sobre la conectividad en ejecución.
- Una familia de catálogo, un punto contractual previsto y una llamada observada requieren capas de grafo y pruebas separadas.
- Eliminar un nodo del catálogo demuestra sensibilidad del modelo, no una caída real.
- Tres nodos de repositorios no permiten establecer el comportamiento de ley de potencias tratado en NET-001.

## Pruebas del proyecto y límites

- Commit de Demerzel `5c4967454ddc740ed937c87719ca4d71a3522e4b`: [registro de capacidades v1.1.0](https://github.com/GuitarAlchemist/Demerzel/blob/5c4967454ddc740ed937c87719ca4d71a3522e4b/schemas/capability-registry.json), [nota sobre contratos entre repositorios](https://github.com/GuitarAlchemist/Demerzel/blob/5c4967454ddc740ed937c87719ca4d71a3522e4b/docs/architecture/cross-repo-contracts.md) y [contrato fuente BAML](https://github.com/GuitarAlchemist/Demerzel/blob/5c4967454ddc740ed937c87719ca4d71a3522e4b/baml_src/schema.baml). Los recuentos de familias 27/4/5 y la intersección de etiquetas compartidas se recalcularon a partir de ese JSON fijado antes de redactar.
- Esta lección trata los nombres de familias como cadenas exactas. No mide la disponibilidad real de herramientas MCP, la compatibilidad de esquemas, el tráfico real, la latencia ni la propagación de fallos. Las afirmaciones de la nota contractual sobre disponibilidad y funcionalidad sin entregar son históricas y deben volver a comprobarse antes de una decisión operativa.
- Durante el ciclo anterior del original inglés, no se había completado ningún intento de un estudiante, revisión de la materia, revisión lingüística por una persona que domine el idioma, sync/build de Learn ni comprobación pública anónima para NET-002. Este borrador en español sigue pendiente de aprobación por una persona que domine el español; traducirlo no acredita ninguno de esos resultados.
