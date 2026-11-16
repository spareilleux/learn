---
module_id: cs-006-ixql-pipeline-composition
department: computer-science
course: Componer etapas IXQL con límites explícitos de las pruebas
level: intermediate
prerequisites: ["cs-005-agent-handoff-evidence-contract"]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
research_cycle: computer-science-2026-10-11-006
version: "0.1.0"
---

# Componer etapas IXQL con límites explícitos de las pruebas

> **Alcance del borrador y las traducciones.** El texto técnico siguiente es un borrador fechado. Las menciones históricas de traducciones, integración en Learn o comprobaciones de publicación pendientes corresponden a aquella etapa; este [registro de traducción](../../../../code/streeling/evidence/locale-completion-2026-10-22/README.md) documenta los borradores actuales y las comprobaciones realizadas. Los ensayos de ejecución no realizados siguen pendientes. Aún faltan la revisión humana del contenido y del idioma, y la prueba con un estudiante.

> **Departamento de Informática** | Nivel intermedio | 35 minutos | Borrador en español; pendientes la revisión del contenido, una prueba con un estudiante y la revisión lingüística humana

## Objetivos

Aprenderás a leer un pipeline IXQL versionado como una secuencia de contratos de etapa, identificar la entrada, salida y posible efecto externo de cada etapa y proponer una comprobación refutable en una frontera de bifurcación. La pregunta del proyecto es práctica: **¿cómo pueden los agentes GA, Demerzel, IX y TARS debatir un mismo flujo de investigación a curso sin confundir una etapa declarada con un resultado ejecutado?**

## 1. Leer la composición que existe

La [gramática IXQL de Demerzel en `0220ca8`](https://github.com/GuitarAlchemist/Demerzel/blob/0220ca84a25f59973bd6b9236cc00b7f68631a50/grammars/sci-ml-pipelines.ebnf) describe las etapas y el flujo de los pipelines. En su sección de orquestación MCP, `identifier <- mcp_step` vincula un resultado, `→` encadena pasos, `parallel(...)` agrupa invocaciones de herramientas y `when` introduce una guarda. Su sección de entrada/salida nombra operaciones como `ix.io.read`, `ix.io.write` e `ix.io.append`. Son construcciones del lenguaje fuente; no demuestran que se ejecutara ningún pipeline concreto.

El [ejemplo fijado de investigación a curso](https://github.com/GuitarAlchemist/Demerzel/blob/0220ca84a25f59973bd6b9236cc00b7f68631a50/examples/ixql/research-to-course.ixql) empieza con lecturas de departamentos y pesos, selecciona un departamento, carga contexto, muestrea una pregunta, investiga, evalúa una conclusión y escribe condicionalmente un curso. Después escribe un registro del ciclo de investigación y describe la acumulación de aprendizajes. Lee las flechas como **flujo de dependencias previsto**: la siguiente etapa necesita un resultado de la anterior. Lee `ix.io.read(...)`, `write(...)` e `ix.io.append(...)` como efectos declarados en las fronteras. Un muestreo de gramática, una respuesta de modelo o una escritura de archivo podrían fallar; la notación por sí sola no muestra el resultado.

Para el debate humano, anota tres líneas reales del ejemplo:

```ixql
departments <- ix.io.read("state/streeling/departments/*.department.json")
question <- dept_context
  → tars.grammar.sample(grammar: dept_context.grammar, weights: dept_context.weights, pattern: "investigation")
  → tars.formulate_question(research_area: department.research_areas)
course <- when conclusion.conclude == "confirm":
  investigation → tars.produce_course(...) → tars.validate_schema(...) → write(...)
```

Los argumentos abreviados anteriores son un **extracto explicativo**, no un sustituto ejecutable del archivo versionado. La primera línea declara una lectura de archivos. La cadena intermedia declara una pregunta derivada del contexto cargado. La última rama declara producción de curso solo para una conclusión `confirm`, con escritura después de la validación. El propio ejemplo indica la ruta y el esquema del curso; consulta sus líneas completas para esos valores exactos.

### Ejercicio práctico 1

En la primera línea, ¿qué se vincula a `departments` y qué pruebas demostrarían que la lectura tuvo éxito en una ejecución real? ¿La línea por sí sola aporta esas pruebas?

> **Respuesta:** Vincula el resultado declarado de leer los archivos JSON de departamentos que coinciden con la ruta. Una ejecución real necesitaría una traza o un recibo que muestre las rutas resueltas, revisiones o hashes de entrada, éxito o fallo y estructura devuelta. La línea describe la lectura, pero no aporta ninguna de esas pruebas de ejecución.

## 2. Dar a cada etapa una entrada y una salida

Un handoff entre agentes es más claro cuando incluye una pequeña tarjeta de etapa. La tabla siguiente es una **anotación didáctica del ejemplo**, no un nuevo sistema de tipos ni sintaxis IXQL:

| Etapa | Entrada requerida | Salida propuesta que inspeccionar | Efecto declarado o incertidumbre |
|---|---|---|---|
| Selección del departamento | archivos de departamentos y pesos | departamento seleccionado y entradas de puntuación | lecturas de archivos; la selección puede fallar si faltan archivos o están mal formados |
| Formación de la pregunta | gramática del departamento, pesos, lista de cursos existentes | pregunta con su contexto fuente | lecturas de contexto y llamadas TARS; evitar duplicaciones está declarado, no demostrado |
| Investigación | pregunta | hallazgos de fuentes y resultado de validación cruzada | llamadas de modelo/MCP; hay que registrar cualquier fuente no disponible |
| Conclusión | pruebas de investigación | `conclude`, creencia, confianza | decisión de rama; los umbrales de este ejemplo son propuestas que inspeccionar |
| Producción del curso | conclusión confirmatoria e investigación | borrador de curso validado | escritura condicional en Streeling; no siguen revisión ni publicación automáticamente |
| Registro del ciclo | conclusión, reflexión, curso, propuesta de gramática | JSON del ciclo de investigación | escritura de archivo; una cadena de ruta no es un recibo persistido |

Esta anotación ofrece un vocabulario compartido a los agentes que cooperan. El productor puede decir «produje una pregunta a partir de estas entradas» y señalar sus pruebas. El receptor puede comprobar que pregunta, contexto y revisión coincidan antes de iniciar la investigación. Las incógnitas explícitas permiten detenerse en la frontera fallida en vez de repetir todas las etapas anteriores. Para cualquier etapa, registra **revisión de fuente, identidad de entrada, identidad de salida, estado, efectos intentados y siguiente acción**. Es un envoltorio de comunicación sugerido en prosa normal o un recibo; la gramática inspeccionada no define esos campos como una construcción IXQL.

### Ejercicio práctico 2

El ejemplo versionado usa `dept_context <- parallel(...)` para leer un archivo de departamento, pesos, gramática y cursos ingleses existentes. ¿Puede tratarse `question <- dept_context → tars.grammar.sample(...)` como completado de forma independiente si falló la lectura de gramática?

> **Respuesta:** No. La etapa de pregunta identifica `dept_context.grammar` como entrada. Una lectura de gramática fallida deja una entrada requerida sin disponibilidad. Informa del fallo y deja la pregunta sin resolver o vuelve a ejecutar desde un contexto verificado. No deduzcas un muestreo válido de la presencia de la línea `question <-`.

### Ejercicio práctico 3

Clasifica estas operaciones del ejemplo como efectos observables externamente o transformaciones propuestas: `ix.io.read`, `tars.grammar.sample`, `tars.cross_validate`, `write(course path, markdown)` e `ix.io.append(grammar path, new_production)`. ¿Cuáles pueden cambiar los bytes del repositorio?

> **Respuesta:** `ix.io.read` es un efecto externo de lectura; `tars.grammar.sample` y `tars.cross_validate` son llamadas de herramientas o modelos cuyo comportamiento y salidas requieren observaciones, por lo que esta lección no las considera puras. `write` e `ix.io.append` son efectos de escritura declarados que pueden cambiar los bytes del repositorio. Un muestreo o validación satisfactorios no implican que ocurriera ninguna escritura.

## 3. Poner un criterio de refutación en la rama

El ejemplo dice `course <- when conclusion.conclude == "confirm": ... → write(...)`. Esta es una **fixture fija de razonamiento**, no un informe de una ejecución real de IXQL:

```text
input: conclusion = { conclude: "refute", belief: "F", confidence: 0.81 }
pre-run course path: absent
expected stage result: no course draft produced; no course-path write
observable check for a test harness: compare file existence and write trace before/after
```

Esta fixture hace refutable la afirmación sobre la rama. Si el harness registra una escritura en la ruta del curso para esa entrada, falló la regla de bifurcación o su implementación. Si no aparece ningún archivo, eso respalda solo este caso; no demuestra que funcionen confirmación, validación, traducción o revisión. Conserva la entrada y la traza de efectos para que otro agente pueda reproducir la conclusión. El umbral `confirm` y la calidad del curso generado son cuestiones independientes.

### Ejercicio práctico 4

Para la fixture fija `refute`, indica la salida esperada y una observación que refutaría la regla de bifurcación. ¿Una variable de curso vacía por sí sola demostraría que no hubo escritura?

> **Respuesta:** Se espera que no se produzca ningún curso ni escritura en su ruta. Una traza que muestre que se llamó a `write(...)`, o un archivo nuevo en esa ruta atribuible a la ejecución, refutaría la regla. Una variable vacía por sí sola no basta porque podría haberse producido un efecto antes de un fallo posterior; inspecciona la traza de escritura y el estado del sistema de archivos.

## 4. Comunicar qué se comprobó

El [validador JavaScript fijado](https://github.com/GuitarAlchemist/Demerzel/blob/0220ca84a25f59973bd6b9236cc00b7f68631a50/scripts/ixql-validate.js) del repositorio se describe como un validador estructural mínimo, no un analizador completo. Divide en tokens los archivos de `pipelines/`, recopila vinculaciones y nombres de controles e informa de problemas. Un informe limpio del validador puede respaldar una afirmación limitada sobre la estructura del código fuente. No puede demostrar que una llamada TARS se resolviera, que se escribiera un curso ni que este superara la revisión con un estudiante. La [especificación de composición de interfaz IXQL](https://github.com/GuitarAlchemist/Demerzel/blob/0220ca84a25f59973bd6b9236cc00b7f68631a50/docs/ixql-ui-composition-spec.md) está marcada como resultado de una exploración de ideas y lista para implementar; esta lección no afirma ninguna ejecución de editor ni interfaz.

Al transferir el pipeline a otro agente, envía una tarjeta de etapa con el archivo y la revisión fijados, etapa exacta, identidades de artefactos de entrada, resultado observado o incógnita explícita, cualquier recibo de escritura y una siguiente acción acotada. [CS-005](cs-005-agent-handoff-evidence-contract.md) desarrolla el contrato general de handoff. Aquí la disciplina adicional es mantener visibles dependencias y efectos en cada etapa IXQL. Un ejemplo fuente, resultado de análisis sintáctico, traza de ejecución, lección revisada y página publicada son artefactos distintos con requisitos de prueba diferentes.

### Ejercicio práctico 5

Un agente informa: «`research-to-course.ixql` pasó `scripts/ixql-validate.js`, así que la nueva lección Streeling está publicada». Corrige la afirmación e identifica las dos comprobaciones siguientes.

> **Respuesta:** La afirmación respaldada es, como máximo, que el validador no encontró problemas estructurales en los archivos que recorrió. Su script recorre `pipelines/`, mientras que `research-to-course.ixql` reside en `examples/ixql/`, así que ese comando ni siquiera demuestra que comprobara ese ejemplo salvo que otra invocación explícita lo hiciera. Después, verifica el ejemplo exacto con un analizador o prueba apropiados y una revisión fijada; luego inspecciona un recibo real de ejecución y los registros de revisión y publicación de la producción del curso antes de afirmar la entrega. Una declaración del código fuente no puede suplir esos registros.

## Fuentes y límites

La gramática, el ejemplo, el validador y la especificación de interfaz están fijados al commit Demerzel `0220ca84a25f59973bd6b9236cc00b7f68631a50`. Esta lección comprueba su texto fuente y usa una fixture sintética de rama; no ejecuta IXQL, prueba un editor IX, observa el ejecutor IX ni valida el ejemplo como ejecutable. La traducción a cinco idiomas y la ruta automática de escritura de cursos del ejemplo describen un flujo previsto; no demuestran que este borrador CS-006 se tradujera, revisara o publicara. La exactitud del contenido, el éxito del estudiante en la tarea y la revisión lingüística humana de este borrador en español siguen pendientes.
