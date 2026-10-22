---
title: Pérdida de información en los handoffs entre agentes
description: Pérdida de información en los handoffs entre agentes — Teoría de la información
sidebar:
  label: INF-004 · Pérdida de información en los handoffs entre agentes
  order: 3
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/information-theory/es/inf-004-information-loss-in-agent-handoffs.es.md
---

:::note[Streeling University]
**INF-004** · Pérdida de información en los handoffs entre agentes · intermedio · 35 minutos

Generado por el departamento *Teoría de la información* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/information-theory/es/inf-004-information-loss-in-agent-handoffs.es.md) · [Mi diario](../../journal/)

Requisitos previos: [INF-002](../../information-theory/inf-002-optick-compact-vector-information-loss/)
:::

> **Alcance de la fuente y la transferencia.** El texto técnico siguiente procede de un borrador archivado. Las menciones históricas de una importación o compilación pendiente en Learn corresponden a aquella etapa; este [registro de transferencia](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/agentic-composition-2026-10-22/README.md) documenta la importación actual y sus comprobaciones. Las demás experiencias indicadas como no realizadas siguen pendientes. Aún faltan la revisión humana del contenido y del idioma, y la prueba con un estudiante.

> **Departamento de Teoría de la Información** | Nivel: intermedio | Duración estimada: 35 minutos | Estado: borrador en español; pendientes la revisión del contenido, una prueba con un estudiante, la revisión lingüística humana y la revisión previa a la publicación

## Objetivos

Después de esta lección podrás:

- Identificar qué hechos garantiza una nota de handoff de GA y cuáles siguen siendo afirmaciones en texto libre.
- Demostrar una colisión con pérdida de información entre estados de entrega distintos.
- Calcular una pérdida de decisión para una pequeña fixture de handoff explícitamente sintética.
- Diseñar un handoff compacto que conserve las pruebas necesarias para una decisión concreta, respetando los límites de las fuentes y de la autoridad.

## La pregunta del proyecto

El [puente Antigravity fijado de GA](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Scripts/antigravity-bridge.ps1) permite que una interfaz de IA deje una nota para otra en `state/handoffs/`. El script registra `from`, una marca temporal, la rama, un identificador corto de head de Git, el número de líneas modificadas del árbol de trabajo y una cadena de handoff de texto libre. Describe el sistema de archivos como el espacio compartido entre las dos IA. Esto ayuda a orientarse, pero el script no verifica pruebas, revisión, responsabilidad de escritura ni publicación. El texto libre puede mencionarlas; el puente no exige su presencia ni garantiza su veracidad.

La pregunta práctica es: **¿puede un handoff breve conservar suficiente información para que el siguiente agente decida si un cambio está listo para integrarse?** Esa pregunta es más limitada que preguntar si la nota resume bien toda una sesión. La respuesta depende de la decisión y de pruebas que el receptor pueda comprobar. Una rama y un titular pueden localizar el trabajo, mientras que una prueba fallida u otro autor activo cambian la decisión de integración.

INF-002 demostró una aplicación de muchos a uno de vectores brutos OPTIC-K a vectores compactos. Aquí aparece la misma forma matemática: dos estados de entrega distintos pueden convertirse en el mismo titular breve. Utilizamos la teoría de la información para examinar la **pérdida relevante para la decisión**, no para afirmar que el puente de GA implemente un código entrópico, que la muestra didáctica estime una tasa real de incidentes ni que un campo de handoff otorgue por sí solo autoridad para fusionar.

## 1. Separar la ubicación de las pruebas

Lee la [rama `Handoff`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Scripts/antigravity-bridge.ps1#L102-L129) del script fijado. Escribe un archivo Markdown con marca temporal y captura la rama, un head corto y el recuento de líneas modificadas mediante Git. Un head corto ayuda a localizar una revisión, pero un artefacto revisado exacto necesita un commit completo e inmutable y, cuando el contenido cambia de forma independiente, un blob de archivo. Un recuento de cero líneas modificadas solo indica lo que contó el comando Git local en ese momento; no demuestra que una prueba se ejecutara ni que pasara. El cuerpo de la nota es lo que el llamante proporcione a `-Handoff`.

El ejemplo del puente dice que una tarea se integró y remite a pruebas. Ese ejemplo orienta a un autor humano, no es un recibo de éxito comprobado por una máquina. Si la decisión del agente receptor es *abrir el archivo correcto*, la rama, head y una ruta pueden bastar. Si la decisión es *integrar este cambio*, también necesita la fuente exacta, el alcance de escritura, el resultado de pruebas vinculado a esa fuente, el resultado de revisión y una vía de integración autorizada. Son preguntas diferentes del receptor, por lo que no existe un resumen de una línea universalmente suficiente.

### Ejercicio práctico 1: identificar las pruebas ausentes

Una nota contiene `branch=feature/audio`, `head=abc1234`, `working_tree_dirty_lines=0` y `Audio work ready`. ¿Qué elementos de los siguientes demuestra el puente: el nombre de la rama, una prueba de audio superada, la responsabilidad de un único autor y la aprobación de la revisión?

> **Respuesta:** El valor de la rama se captura desde Git local cuando el script escribe la nota. El script no registra ningún veredicto de pruebas, declaración de responsabilidad ni veredicto de revisión; `ready` es texto sin verificar. El head corto y el recuento de cero líneas modificadas no cubren esas carencias. Incluso el valor de la rama es una observación local, no una prueba de que la rama remota o sus fuentes revisadas tengan el mismo estado más adelante.

## 2. Una pequeña colisión con una consecuencia medible

La [fixture fija de INF-004](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/information-theory/inf-004/handoff-cases.json) contiene cuatro casos inventados, todos con el titular `ready`. Cada caso incluye tres hechos booleanos: `tests_passed`, `single_writer` y `review_approved`. Solo para esta **decisión didáctica**, un caso es admisible si los tres son verdaderos. Un proyecto real también necesitaría comprobar la fuente exacta y la autorización; el modelo simplificado las omite para aislar un mecanismo de pérdida de información.

| Caso | Titular | Pruebas superadas | Autor único | Revisión aprobada | Admisibilidad del modelo |
|---|---|---|---|---|---|
| A | ready | sí | sí | sí | sí |
| B | ready | no | sí | sí | no |
| C | ready | sí | no | sí | no |
| D | ready | sí | sí | no | no |

El codificador del titular convierte cuatro estados de pruebas diferentes en la misma salida. Un receptor que solo ve `ready` no puede distinguir A de B, C o D. Esto demuestra una colisión en la fixture; no demuestra con qué frecuencia resulta engañoso un handoff real de GA. El [evaluador local](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/information-theory/inf-004/evaluate_handoffs.py) reproduce la tabla y los costes:

```powershell
python state/streeling/fixtures/information-theory/inf-004/evaluate_handoffs.py
```

### Ejercicio práctico 2: construir el contraejemplo

¿Qué pareja de casos basta para refutar la afirmación «el titular `ready` determina de forma única la admisibilidad»? ¿Qué información se perdió?

> **Respuesta:** A y B tienen el mismo titular, pero A supera los tres controles del modelo mientras que B falla el de pruebas. Su valor codificado idéntico tiene una admisibilidad diferente, por lo que el titular no puede determinar la decisión. A y C o A y D también sirven. Se perdió al menos el valor del control que los distingue.

## 3. Asignar un coste a la decisión errónea y cuestionar el modelo

La fixture asigna un coste inventado de 10 unidades a aceptar un caso no admisible y de 1 unidad a rechazar uno admisible. Son pesos didácticos, no costes observados de defectos. Un receptor que solo dispone del titular debe tomar la misma acción para los cuatro casos. `accept all` produce tres falsas aceptaciones: coste total `3 × 10 = 30`, coste medio `30/4 = 7.5`. `reject all` produce un falso rechazo: coste total `1`, coste medio `1/4 = 0.25`. Con esta muestra y estos costes asimétricos, la acción constante de menor coste es rechazar todos. El objetivo no es recomendar el rechazo generalizado, sino mostrar por qué un mensaje comprimido puede forzar una mala elección.

Con los tres booleanos de prueba disponibles y fiables **dentro de la fixture simplificada**, el receptor aplica la regla del modelo a cada caso y no comete errores de clasificación, con un coste medio de cero. En un flujo de trabajo real, añadir texto booleano no bastaría para hacerlo fiable. Las pruebas deberían enlazar a un comando, resultado y revisión exacta; la responsabilidad de escritura, a una declaración o un alcance acordado; la revisión, a un veredicto identificable sobre el blob exacto. El receptor puede entonces verificar cada enlace en lugar de confiar en un estado autodeclarado.

### Ejercicio práctico 3: calcular la pérdida de decisión

Para las cuatro filas y los costes indicados, calcula la pérdida media de `accept all`, `reject all` y la regla simplificada con todas las pruebas. ¿Qué acción constante es más barata aquí?

> **Respuesta:** `accept all`: tres falsas aceptaciones cuestan 30 en total, es decir, `7.5` por caso. `reject all`: solo A es un falso rechazo con coste total 1, es decir, `0.25` por caso. La regla con todas las pruebas clasifica correctamente las cuatro filas del modelo y cuesta `0`. Rechazar todos es la acción **constante** más barata para esta muestra inventada y esta elección de costes, no una política general del proyecto.

### Ejercicio práctico 4: comprobar la sensibilidad

Mantén los cuatro casos, pero cambia el coste de falsa aceptación de 10 a `0.1`, dejando el de falso rechazo en 1. Este caso de sensibilidad es un cálculo manual: el evaluador fijado solo acepta costes con valor entero y rechazará una fixture JSON que use `0.1` sin modificar el evaluador. ¿Qué acción constante tiene menor coste medio? ¿Qué enseña la inversión del resultado?

> **Respuesta:** `accept all` cuesta ahora `3 × 0.1 / 4 = 0.075`; `reject all` sigue en `1/4 = 0.25`, así que aceptar todos es más barato con los nuevos pesos. La mejor acción depende del modelo de pérdida de la decisión. Ningún conjunto de costes inventados estima el coste real de una integración incorrecta ni demuestra qué debería automatizar GA.

## 4. Conservar el handoff mínimo comprobable

Para una decisión de integración, propón un registro de handoff con un commit **completo** y los identificadores de blob pertinentes; repositorio, rama y worktree; el autor único y su alcance de escritura; el comando de pruebas, resultado de salida y revisión de fuentes; el veredicto de revisión y el blob revisado; y la siguiente acción exacta solicitada. El destinatario debería comparar de forma independiente esas referencias con el checkout actual y el estado de revisión. Es un contrato de handoff candidato, no una afirmación de que el puente actual de GA lo emita o valide. Es deliberadamente específico para la tarea: un handoff de navegación visual puede necesitar una captura de pantalla o una línea de archivo en lugar de un veredicto de revisión.

¿Por qué no copiar una transcripción entera? Puede contener mucho contexto irrelevante, afirmaciones obsoletas y material que el receptor no pueda comprobar rápidamente. La pregunta de diseño más útil es qué hechos son **suficientes para la siguiente acción concreta** y qué incertidumbre debe seguir siendo explícita. Un registro compacto puede apuntar a artefactos inmutables más grandes. Si las referencias no se pueden resolver o el blob revisado es diferente, la decisión de integración debería detenerse a la espera de nuevas pruebas, sin deducir silenciosamente el éxito de la palabra `ready`.

### Ejercicio práctico 5: escribir un handoff refutable

Recibes `GA audio change ready; tests pass`. Escribe los campos complementarios mínimos para decidir si integrarlo. Indica una observación que refutaría el estado `ready` declarado.

> **Respuesta:** Solicita el commit completo de GA y los identificadores de los blobs cambiados, el worktree y la rama, el alcance de escritura de un único autor, el comando exacto de pruebas de audio y su resultado vinculados a ese commit, el veredicto de revisión vinculado a esos blobs y la acción o autoridad de integración solicitada. Si la prueba registrada se ejecutó en otro commit, un revisor vio otro blob u otro autor es responsable de los mismos archivos, queda refutada la preparación declarada para integrar. Esto no exige que la nota demuestre la calidad del audio; eso necesita su propio protocolo de escucha y evaluación de la señal.

## Límites y próxima comprobación

El script fijado de GA en el commit `dc2e74cbd992a298f67efb928b5b3754615e1924` establece qué escribe el puente, no la veracidad de ningún handoff pasado. Las cuatro filas y los costes son sintéticos. El evaluador comprueba la aritmética y la estructura básica de la fixture; no mide la compresión en bits, las tasas reales de error de los agentes, la procedencia de las pruebas ni la seguridad de las fusiones. El siguiente experimento acotado tomaría una muestra de handoffs reales autorizados, definiría de antemano la decisión del receptor, compararía cada nota con recibos inmutables de pruebas, revisión y fuentes, y contaría los hechos ausentes críticos para la decisión. La privacidad y la autorización regirían ese muestreo. No reducir las decisiones erróneas o retrasadas respecto al puente existente refutaría el formato enriquecido propuesto.
