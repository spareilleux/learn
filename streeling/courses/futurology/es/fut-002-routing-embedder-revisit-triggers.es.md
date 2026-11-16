---
module_id: fut-002-routing-embedder-revisit-triggers
department: futurology
course: Condiciones para revisar el embedder de enrutamiento de GA
level: early-intermediate
prerequisites: [fut-001-thinking-about-tomorrow]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
research_cycle: futurology-2026-10-11-002
version: "0.1.0"
---

# ¿Cuándo debería GA revisar su embedder de enrutamiento?

> **Alcance de la fuente y la transferencia.** El texto técnico siguiente procede de un borrador archivado. Las menciones históricas de traducciones todavía no redactadas, de una importación o compilación pendiente en Learn corresponden a aquella etapa; este [registro de transferencia](../../../../code/streeling/evidence/representation-release-2026-10-22/README.md) documenta los borradores traducidos actuales, la importación y sus comprobaciones. Las demás experiencias indicadas como no realizadas siguen pendientes. Aún faltan la revisión humana del contenido y del idioma, y la prueba con un estudiante.

> **Departamento de Futurología** | Nivel: intermedio inicial | Duración estimada: 35 minutos | Estado: borrador en español; pendientes la revisión del contenido, una prueba con un estudiante, la revisión lingüística humana y la revisión previa a la publicación

## Objetivos

Después de esta lección podrás:

- Separar una elección histórica de modelo, su método de evaluación y una condición futura que justificaría revisarla.
- Calcular el margen respecto a un umbral declarado sin presentar un pequeño benchmark como una previsión de despliegue.
- Explicar por qué un cambio de modelo necesita su propio barrido del umbral de confianza y por qué ocho prompts fuera de alcance dan una tasa poco precisa.
- Escribir una respuesta a un escenario acotado: qué medir, qué rama selecciona y qué observación refutaría la rama preferida.

## La pregunta del proyecto

En el commit fijado de GA [`dc2e74cbd992a298f67efb928b5b3754615e1924`](https://github.com/GuitarAlchemist/ga/tree/dc2e74cbd992a298f67efb928b5b3754615e1924), la configuración de enrutamiento del chatbot indica `bge-large` con `MinConfidence: 0.64`. El [plan de evaluación](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/docs/plans/2026-06-16-ml-text-embedder-evaluation-plan.md) describe ese cambio de enrutamiento como entregado en su fecha histórica y reversible restaurando dos valores de configuración. Aplaza un posible cambio global del embedder del almacén de memoria porque exigiría pruebas independientes y una migración del índice persistente. El [archivo appsettings fijado](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Apps/GaChatbot.Api/appsettings.json) corrobora el modelo de enrutamiento y el umbral; no es una comprobación de un despliegue activo.

La pregunta útil para el futuro no es «¿qué modelo ganará el próximo año?», sino: **¿qué observación nueva haría que mereciera la pena reabrir esta decisión concreta de enrutamiento?** Esta lección construye un pequeño registro de desencadenantes a partir del benchmark y del registro de validación fijados. [FUT-001](fut-001-thinking-about-tomorrow.md) enseña horizontes amplios y escenarios 2×2. Aquí un escenario es una rama acotada de **si se mide una condición, entonces realizar la siguiente prueba**. No tiene probabilidades inventadas ni fechas límite de calendario. La rama puede estar equivocada; las pruebas necesarias para rechazarla forman parte del diseño.

## 1. Fijar la decisión y las dos etapas de evaluación

El [informe comparativo de Phase 0](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/embedder-bakeoff/bakeoff-latest.md) evaluó 166 prompts dentro de alcance distribuidos en 16 intenciones. Su resultado de validación cruzada de cinco particiones, con coseno y un vecino más cercano, es un **indicador indirecto del mecanismo del enrutador**, no toda la pila de enrutamiento de producción. También informa de la silueta de intenciones y de la latencia de **un único embedding**. El [artefacto numérico del comparativo](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/embedder-bakeoff/bakeoff-latest.json) da para `bge-large` una latencia p95 de `238.27479999454226 ms` y para la referencia nomic de `101.44889999355655 ms`. El informe elige un presupuesto p95 de 500 ms para la ruta de chat e indica que los candidatos lo cumplen. Comparar un único embedding con ese presupuesto no demuestra un p95 de chat medido de extremo a extremo.

| Modelo de Phase 0 | Exactitud indirecta de validación cruzada | p95 de un único embedding | Papel en la decisión |
|---|---:|---:|---|
| `nomic-embed-text` | 0.644 | 101.449 ms | Referencia anterior de enrutamiento |
| `bge-large` | 0.705 | 238.275 ms | Ganador del indicador indirecto; debe pasar por el harness completo |

La [validación posterior de Phase 2](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/embedder-bakeoff/phase2-validation-2026-06-16.md) ejecutó el `RoutingEvalHarness` completo con descripciones, refuerzos por pistas y un umbral de confianza. Sus cifras de exactitud **no** deben restarse de las cifras indirectas de Phase 0 como si fueran las mismas pruebas. En el harness completo, la referencia nomic con umbral `0.55` tuvo exactitud dentro de alcance de `0.934` y rechazo fuera de alcance (OOS) de `0.875`. `bge-large` con el mismo `0.55` mantuvo una exactitud dentro de alcance de `0.946`, pero solo rechazó `0.375` de los prompts OOS. Tras recalibrarlo a `0.64`, mantuvo `0.946` dentro de alcance y rechazó `1.000` de los prompts OOS **en esa ejecución de validación**.

Por tanto, el cambio dependía de una **pareja**, modelo y umbral. Un embedder nuevo puede cambiar la escala de las puntuaciones coseno, por lo que copiar el umbral del modelo anterior puede forzar rutas para prompts desconocidos. El plan fijado pide repetir el barrido de umbrales por prompt en futuros cambios y mantener alineados los ajustes del harness y de producción. Ni una puntuación indirecta mayor ni un umbral copiado bastan para promocionar un modelo.

### Ejercicio práctico 1: calcular el margen de latencia

Con el artefacto numérico de Phase 0, resta el p95 de un único embedding de `bge-large` del presupuesto de 500 ms del informe. ¿Cuánto más lento fue su p95 medido que el de nomic? ¿Qué afirmación sigue sin estar respaldada?

> **Respuesta:** El margen aritmético es `500 - 238.27479999454226 = 261.72520000545774 ms`, aproximadamente **261.7 ms**. La diferencia respecto a nomic es `238.27479999454226 - 101.44889999355655 = 136.8259000009857 ms`, aproximadamente **136.8 ms**. Ambas son comparaciones de un único embedding de esa ejecución fija. No demuestran el p95 de chat de extremo a extremo, el comportamiento con otro host o carga ni una garantía futura de latencia.

### Ejercicio práctico 2: comparar medidas equivalentes

¿Cuánto aumentó la exactitud dentro de alcance del harness completo entre nomic a `0.55` y `bge-large` recalibrado a `0.64`? ¿Por qué `0.946 - 0.705` es una comparación incorrecta para esa pregunta?

> **Respuesta:** `0.946 - 0.934 = 0.012`, es decir, **1.2 puntos porcentuales**, en la comparación del harness completo. La cifra `0.705` es la exactitud indirecta de `bge-large` en Phase 0 con un vecino más cercano, obtenida mediante otro método. Restarla de Phase 2 mezclaría medidas diferentes y no daría una mejora del modelo.

## 2. Convertir el barrido de umbrales en ramas acotadas

Empieza con una referencia registrada y escribe **qué medición nueva cambia la acción**. Usa el `0.934` histórico dentro de alcance como umbral de promoción del plan. Sigue por separado el rechazo OOS como salvaguarda; el informe de Phase 2 advierte de que solo se etiquetaron **ocho prompts OOS**. Un cambio de un prompt mueve esa tasa en `1/8 = 12.5` puntos porcentuales. El presupuesto de 500 ms se aplicó a la métrica de un único embedding del comparativo, por lo que corresponde incluir una medición nueva y comparable de latencia en el registro; antes de prometer un nivel de servicio de chat hace falta otra medición de extremo a extremo.

| Rama futura | Observación que recoger | Siguiente acción acotada |
|---|---|---|
| **Conservar y vigilar** | El resultado comparable dentro de alcance del harness completo sigue superando el umbral histórico; las pruebas OOS no muestran una regresión estable; la latencia sigue dentro del presupuesto elegido | Mantener provisionalmente la pareja de enrutamiento y ampliar el conjunto OOS etiquetado. Registrar fecha, corpus, umbral, host y versión del modelo. |
| **Recalibrar** | La exactitud dentro de alcance se mantiene, pero el rechazo OOS cae tras un cambio de modelo, mezcla de prompts o distribución de puntuaciones | Inspeccionar las puntuaciones por prompt, barrer umbrales y volver a ejecutar el harness completo antes de cambiar la pareja configurada. No suponer que el antiguo `0.64` sirve para otro modelo. |
| **Comparar o revertir** | Una ejecución comparable falla el umbral histórico dentro de alcance, o una nueva medición falla el umbral de latencia | Reproducir el resultado, comparar con el modelo anterior en las mismas condiciones y usar la configuración reversible de enrutamiento del plan si procede revertir. |

Estas son **reglas de decisión para investigar**, no afirmaciones de que alguna rama haya ocurrido. Las pruebas OOS deben considerarse junto con su tamaño de muestra y tipo de error, en lugar de aplicar un umbral universal copiado de ocho ejemplos. Un modelo nuevo también necesita distinguir su alcance de enrutamiento y memoria: el plan fijado desacopló deliberadamente el enrutamiento del embedder de memoria persistente. Extender una victoria de enrutamiento al almacén de memoria sería una decisión diferente, con una migración importante.

### Ejercicio práctico 3: ver qué cambió con la calibración

En el barrido de umbrales de Phase 2, ¿qué hizo pasar `bge-large` de `T=0.55` a `T=0.64` al rechazo OOS y a la exactitud dentro de alcance? Convierte las tasas OOS en recuentos usando los ocho prompts OOS del informe.

> **Respuesta:** El rechazo OOS pasó de `0.375 = 3/8` a `1.000 = 8/8`, una ganancia de **cinco prompts rechazados** o **62.5 puntos porcentuales** en esa muestra de validación. La exactitud dentro de alcance se mantuvo en `0.946`. Esto no establece cuántos prompts OOS futuros, con otra distribución, se rechazarán.

### Ejercicio práctico 4: probar un umbral demasiado estricto

Con `T=0.72`, el barrido informa de `0.934` dentro de alcance; con `T=0.75`, de `0.916`. ¿Cuál supera el resultado histórico nomic de `0.934` dentro de alcance y por cuánto lo incumple `0.75`?

> **Respuesta:** Ninguno supera `0.934`: `0.72` solo lo **iguala**, mientras que `0.75` queda `0.934 - 0.916 = 0.018`, es decir, **1.8 puntos porcentuales por debajo**. Ambos umbrales informan de un rechazo OOS de `1.000` en el pequeño conjunto de validación, lo que muestra por qué el éxito OOS por sí solo no basta para decidir el enrutamiento.

## 3. Exponer el contraargumento y el criterio de refutación

El contraargumento más sólido para considerar `bge-large` un ganador duradero es concreto. Su p95 medido de un único embedding fue unos 136.8 ms más lento que el de nomic en Phase 0. La tasa de validación OOS procedía de ocho prompts y el [estado fechado del plan](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/docs/plans/2026-06-16-ml-text-embedder-evaluation-plan.md#L124-L146) registra una **repetición local de 7/8**, no los 8/8 de la validación. Un responsable podría preferir razonablemente el modelo anterior, más barato, si una carga nueva y comparable muestra que la ganancia de calidad medida no existe o que el coste en latencia supera el presupuesto pertinente. Los artefactos fijados no muestran por sí solos que esto haya ocurrido.

Por tanto, un criterio útil de refutación es un resultado nuevo y versionado del harness completo, con el umbral realmente configurado, que caiga **por debajo del umbral histórico de 0.934 dentro de alcance**, o un p95 medido comparable que supere el umbral de latencia acordado. Un conjunto OOS mayor que muestre un problema reproducible de rechazo también obligaría a comparar umbrales y candidatos. Registra el denominador, las identidades de los prompts o la revisión estable del corpus, el host y las versiones de herramientas; de lo contrario, un cambio aparente puede ser una variación de la medición. No deduzcas una tendencia monótona de dos ejecuciones con ocho ejemplos OOS ni extrapoles linealmente la latencia a partir de la concurrencia sin medirla.

### Ejercicio práctico 5: interpretar un denominador pequeño

La validación de Phase 2 informó de un rechazo OOS de `8/8`; la repetición local posterior informó de `7/8`. ¿Cuáles son las dos tasas y su diferencia? ¿Esto demuestra que la calidad del enrutamiento empeoró tras la entrega?

> **Respuesta:** `8/8 = 1.000` y `7/8 = 0.875`, una diferencia de **0.125**, o **12.5 puntos porcentuales**, causada por un prompt de ocho. Los registros por sí solos no demuestran una tendencia de deterioro: son dos ejecuciones fechadas sobre un conjunto OOS muy pequeño y la lección no ha establecido que los prompts y las condiciones sean idénticos. La siguiente comprobación útil es una evaluación OOS mayor y versionada junto con el harness completo dentro de alcance.

## Límites y seguimiento del proyecto

Este es un ejercicio histórico de decisión vinculado a una revisión. La configuración fijada demuestra la intención del repositorio, no lo que sirve ahora un proceso activo de GA. Phase 0 es un indicador indirecto del enrutamiento, Phase 2 es un harness más completo y ninguno es una previsión a largo plazo. Los ocho ejemplos OOS hacen que las tasas sean poco precisas. La comparación de 500 ms se basa en la medición comunicada de un único embedding frente a un presupuesto elegido; una afirmación de nivel de servicio de la ruta de chat requiere su propia medición. Un candidato futuro también necesitaría calibración, paridad de umbrales entre harness y producción y un despliegue reversible. Nada de esto autoriza recalcular globalmente los embeddings de memoria.

Si llegan pruebas nuevas, actualiza el registro de desencadenantes antes de cambiar el modelo. Una buena entrada nombra la observación, su revisión de origen, qué rama selecciona, un contraargumento y la medición que podría invertir la decisión. Eso crea una respuesta futura auditable sin fingir que se sabe cuándo ocurrirá la rama o si llegará a ocurrir. Esta lección en español sigue siendo un borrador; siguen pendientes la revisión del contenido, un intento de estudiante, la revisión lingüística humana y la verificación de publicación.

## Fuentes fijadas

- [Informe y método del comparativo de GA Phase 0](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/embedder-bakeoff/bakeoff-latest.md) y [resultados numéricos](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/embedder-bakeoff/bakeoff-latest.json), ambos en `dc2e74cbd992a298f67efb928b5b3754615e1924`.
- [Barrido de umbrales del harness completo de GA Phase 2](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/embedder-bakeoff/phase2-validation-2026-06-16.md), [plan de decisión](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/docs/plans/2026-06-16-ml-text-embedder-evaluation-plan.md) y [configuración del chatbot](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Apps/GaChatbot.Api/appsettings.json), en el mismo commit.
