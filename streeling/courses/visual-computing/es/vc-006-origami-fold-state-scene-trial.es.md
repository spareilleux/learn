---
module_id: vc-006-origami-fold-state-scene-trial
department: visual-computing
course: "Probar el significado del estado de pliegue en una escena de Blender a Godot"
level: intermediate
prerequisites: [vc-005-craft-details-through-blender-to-godot]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
research_cycle: visual-computing-2026-10-12-006
version: "0.1.0"
---

# Probar el significado del estado de pliegue en una escena de Blender a Godot

> **Alcance de la fuente y la transferencia.** El texto técnico siguiente procede de un borrador archivado. Las menciones históricas de traducciones todavía no redactadas, de una importación o compilación pendiente en Learn corresponden a aquella etapa; este [registro de transferencia](../../../../code/streeling/evidence/representation-release-2026-10-22/README.md) documenta los borradores traducidos actuales, la importación y sus comprobaciones. Las demás experiencias indicadas como no realizadas siguen pendientes. Aún faltan la revisión humana del contenido y del idioma, y la prueba con un estudiante.

> **Departamento de Computación Visual** | Intermedio | 40 minutos | Borrador en español; sin recurso plegado, importación a Godot, prueba con estudiantes, revisión humana ni publicación; aprobación lingüística por una persona que domine el español pendiente

## Objetivos y pregunta del proyecto

Después de esta lección, podrás especificar una pequeña prueba de escena con superficie plegada, distinguir geometría, material y semántica del pliegue, diagnosticar la pérdida de una señal de estado y redactar criterios que rechacen un recurso atractivo pero engañoso. **Pregunta del proyecto:** ¿podría un panel de gobernanza plegable en el observatorio Godot propuesto de GA mostrar dos estados de política distintos conservando el estado que un estudiante puede identificar? Es un diseño de prueba. No afirma que exista un objeto de origami, un DSL de estados de pliegue ni una escena Godot funcional.

El [plan de integración Godot](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/docs/plans/parked/2026-03-28-feat-godot-integration-plan.md) fijado de GA esboza una escena de gravedad constitucional y trabajo de retroalimentación de capturas como elementos sin completar. El [anfitrión React de Godot](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/ReactComponents/ga-react-components/src/components/PrimeRadiant/GodotScene.tsx) fijado declara una iframe y gestión de mensajes; no demuestra una escena exportada. [VC-004](vc-004-godot-observatory-capture-gate.md) propone una condición reproducible de captura y [VC-005](vc-005-craft-details-through-blender-to-godot.md) trata la conservación de pequeños detalles artesanales al limpiar GLB. Aquí el problema central es distinto: una arista visible puede sobrevivir mientras se pierde la *identidad, dirección o significado de política* de su pliegue.

## 1. Definir el contrato de estado de pliegue antes de modelar

Usa una **fixture sintética** deliberadamente pequeña: tres paneles etiquetados A, B y C con dos bisagras. El pliegue `e1` une A con B; `e2` une B con C. Un manifiesto externo de prueba asigna a cada pliegue un ID, ID de paneles incidentes, un estado y una etiqueta semántica. En el ejemplo, el estado `closed` significa que `e1` es un pliegue montaña y `e2` un pliegue valle; `open` significa que ambos paneles han vuelto a una pose declarada casi plana. Montaña y valle nombran la orientación con signo de la fixture, no una lectura universal de cualquier malla. Fija en el manifiesto el orden de vértices de las caras, dirección del pliegue, lado de observación y convención de signos antes de registrar ángulos. De lo contrario, invertir la vista o las normales podría invertir la etiqueta sin mover vértices.

Para el observatorio propuesto, da a `closed` el significado de prueba «se retiene una dependencia de política» y a `open` «la dependencia está disponible». Son significados de interfaz inventados, no afirmaciones de un protocolo de gobernanza existente ni de una tradición histórica de origami. Conserva el manifiesto fuera de la malla exportada y relaciona sus ID estables de pliegues con objetos de escena tras importar. Un recurso que muestre dos poses atractivas pero sin correspondencia recuperable `e1`/`e2` no satisface el requisito de interacción de esta prueba.

### Ejercicio 1: encontrar el contrato ausente

Un modelador entrega dos capturas etiquetadas `open` y `closed`, además de un GLB. El GLB tiene una arista visible, pero no ID de pliegues ni registro de adyacencia de paneles. ¿Puede un revisor verificar que `e1` cambió de estado y sigue representando la dependencia de política?

> **Respuesta:** No. Las imágenes pueden respaldar una diferencia visual, pero no identifican qué arista es `e1`, qué paneles une ni qué estado de política significa. Añade un manifiesto externo versionado con ID de paneles y pliegues, adyacencia, convención de ángulos con signo, correspondencia de estado y significado y hashes de GLB y escena. Después prueba la correspondencia tras importar con una selección o cambio de estado intencional. Una arista por sí sola no es un comprobante semántico.

## 2. Separar pruebas geométricas, materiales y semánticas

La **geometría** incluye vértices, caras, adyacencia de paneles, silueta, grosor, normales y pose medida. El [script de modelado](https://github.com/spareilleux/learn/blob/93d424f872a576ba8bbcd3dd44c9733292373654/code/blender/scripts/l02_modeling.py) fijado de Learn construye un plano abierto de un cuadrilátero y un ejemplo de tres cuadriláteros que comparten una arista; su [informe versionado](https://github.com/spareilleux/learn/blob/93d424f872a576ba8bbcd3dd44c9733292373654/code/blender/expected/l02_modeling.txt) registra aristas de borde y no manifold. Esos ejemplos demuestran cómo inspeccionar topología, no que un recurso plegado concreto sea válido. Una hoja tiene aristas de borde intencionalmente; exigir cero rechazaría la hoja de forma incorrecta. En cambio, una bisagra no manifold o una cara duplicada desconectada necesita investigación aunque un renderizado parezca suave.

El **material** incluye color base, textura, disposición UV, rugosidad y sombreado. El [script de materiales y glTF](https://github.com/spareilleux/learn/blob/93d424f872a576ba8bbcd3dd44c9733292373654/code/blender/scripts/l03_materials.py) fijado de Learn y su [informe de referencia](https://github.com/spareilleux/learn/blob/93d424f872a576ba8bbcd3dd44c9733292373654/code/blender/expected/l03_materials.txt) muestran coordenadas UV en esquinas de caras e inspeccionan atributos de malla y valores de material de un glTF exportado. No prueban nuestro panel plegado propuesto. Una línea oscura pintada puede señalar visualmente un pliegue mientras la geometría sigue plana; una arista geométrica puede permanecer al perderse textura o UV. Captúralo como observaciones separadas.

La **semántica del pliegue** incluye `e1` y `e2`, orden de paneles, estado montaña/valle bajo la convención declarada, transiciones permitidas y significado de gobernanza asignado. Un renderizado GLB o un recuento de triángulos no establece nada de eso. Guarda la semántica en un archivo auxiliar para la prueba y verifica después que la escena Godot vincule los ID previstos a la transición prevista. Ese archivo es una fixture propuesta, no un esquema ni formato de despliegue implementados.

### Ejercicio 2: clasificar tres observaciones

En una importación hipotética, (a) la silueta se dobla donde se espera, (b) una línea azul marca el pliegue pero desaparece al cambiar el material y (c) al pulsar el objeto `e1` renderizado aparece la etiqueta de política `e2`. ¿Qué capa prueba cada observación y cuál incumple la prueba?

> **Respuesta:** (a) es prueba geométrica, aunque no demuestra por sí sola la identidad del pliegue. (b) es prueba de material; su desaparición muestra que la señal es vulnerable a cambios de material. (c) prueba la vinculación semántica de la escena y falla porque `e1` selecciona la etiqueta `e2`. Corrige la correspondencia de ID y repite la traza de interacción; reparar solo el shader no corregiría el error.

## 3. Hacer medible la pose sin convertir el ángulo en significado

Para una prueba, registra la transformación fuente de cada panel y las dos poses de bisagra en Blender, exporta un estado congelado cada vez y registra el ángulo firmado previsto en el manifiesto externo. Puede calcularse un ángulo a partir de normales de paneles orientadas de forma coherente alrededor de un pliegue dirigido; sin esa orientación solo es una magnitud de flexión sin signo. Define un objetivo sintético de `+60°` para `e1` y `−60°` para `e2` en `closed`, y una desviación respecto al plano dentro de `±5°` para cada uno en `open`. Son tolerancias didácticas, no comportamiento medido de Godot ni una norma de plegado de papel. El manifiesto debería registrar escala de unidades, ajustes de exportación, convención de coordenadas y nombres de objetos de panel y pliegue. Si la exportación aplica transformaciones o cambia ejes, el adaptador de escena debe conservar expresamente la correspondencia de signos.

Antes de intentar animación, compara instantáneas estáticas. Importa GLB fuente y candidato en la misma escena Godot versionada con iguales escala y cámara. Guarda registros de importación, correspondencia de nombres, capturas brutas en panel y pantalla completa y trazas de interacción de ambos estados. Inspecciona vistas frontal y posterior: una línea solo de material puede desaparecer por detrás y un pliegue puede ocultar un panel desde una cámara. Una futura prueba de animación necesitaría estados intermedios y comprobaciones de autointersección; dos extremos no certifican un movimiento de plegado físicamente realizable.

### Ejercicio 3: evaluar una pose sintética

Bajo la convención de signos declarada, una importación candidata `closed` mide `e1 = +58°` y `e2 = +61°`. La tolerancia es de cinco grados alrededor de cada objetivo. ¿Qué bisagra pasa y por qué una captura clara es insuficiente para aprobar el estado?

> **Respuesta:** `e1` pasa porque `|58 − 60| = 2°`. `e2` falla porque `|61 − (−60)| = 121°`; la magnitud se parece al objetivo, pero el signo está invertido. Comprueba el orden de vértices de las caras y la correspondencia de escena antes de decidir si lo causó la geometría o la convención de medida. Una captura desde un lado puede ocultar el error de signo y no dice nada de la etiqueta de política `e2`.

## 4. Comparar una característica cada vez en el observatorio

Prepara una referencia con un panel plano estático y una etiqueta textual sencilla de estado. Es una interfaz más simple y podría resultar más clara que una forma plegada. El candidato plegado solo merece adoptarse si los usuarios identifican ambos estados y la dependencia prevista al menos con la misma fiabilidad en la misma tarea, dentro de un coste de escena acordado. Mantén fijos instantánea de datos de gobernanza, etiquetas, viewport, renderizador, iluminación, cámara, compilación y secuencia de entradas. Para comparar geometría, varía la malla plegada manteniendo señales materiales fijas. Para comparar material, usa la misma malla y pose y cambia la señal de pliegue. Para la vinculación semántica, inyecta la misma transición nombrada e inspecciona el ID seleccionado y la etiqueta de política resultante. No trates una captura conjunta como prueba de las tres capas.

Usa como controles las capturas brutas repetidas y la traza de clics propuestas en VC-004. Declara la prueba pequeña por adelantado: tres capturas repetidas de cada estado en panel y pantalla completa; ningún ID de objeto ausente; ningún error de importación; ángulos dentro de tolerancia; y clics intencionales en `e1` y `e2` en cada pose que produzcan el ID, estado y etiqueta declarados de cada pliegue en todas las trazas. En una tarea inicial de comprensión, pide a cuatro revisores que elijan `open` o `closed` y nombren la dependencia sin superponer respuestas. Exige al menos el número de aciertos de la referencia plana con texto, no un porcentaje universal derivado de cuatro personas. Conserva respuestas y errores individuales. Registra recuento de triángulos y distribución de tiempo por fotograma en el mismo dispositivo, pero elige un límite de coste desde una medida real de referencia antes de usarlo para aceptar. No se midió esta prueba propuesta para la lección.

### Ejercicio 4: aislar la causa

El candidato X utiliza una nueva malla plegada, textura azul de pliegue, cámara y etiqueta de política revisada. Cuatro revisores identifican su estado `closed`. La referencia plana textual consigue tres. ¿Demuestra que la geometría plegada mejoró la comprensión? Diseña la siguiente comparación.

> **Respuesta:** No. Geometría, material, cámara y texto cambiaron juntos, y cuatro observaciones son demasiado pocas para una afirmación amplia. Restaura cámara y etiqueta de referencia, mantén fijo el material del pliegue y compara geometría plana y plegada con la misma tarea. Después varía la señal material con geometría fija. Guarda respuestas por revisor y capturas brutas; comunica la prueba pequeña como resultado local solo si realmente se ejecuta.

## 5. Decidir si el pliegue pertenece a un lenguaje de escenas componible

La implementación viable más sencilla es un recurso de Blender, un pequeño manifiesto externo y una correspondencia explícita de ID de objetos de Godot revisada frente a capturas brutas y clics. Una futura descripción componible de escena podría declarar `panel`, `crease`, `adjacent_to`, `signed_pose`, `state` y `meaning`. No debería adoptarse solo porque las palabras se compongan sobre el papel. El contraargumento más sólido es que un panel plano con texto comunica el mismo estado con menos trabajo de modelado, importación, accesibilidad y mantenimiento. Los costes ocultos incluyen crear y validar ID estables, conservar signos en conversiones de coordenadas, mantener señales frontales/posteriores y traducir etiquetas independientemente de la geometría. Un lenguaje propuesto tendría que reducir errores observados o tiempo de revisión respecto al manifiesto y la lista de comprobación.

**Acepta el candidato de prueba** solo tras una importación versionada de Godot y pruebas brutas que muestren ID y vínculos correctos, ángulos dentro de tolerancia, ningún panel ausente, comprensión al menos igual a la referencia y coste medido dentro de un presupuesto predeclarado. **Recházalo o revísalo** si una inversión de signo o etiqueta incorrecta supera la revisión visual, la comprensión cae bajo la referencia, la correspondencia de ID no puede reproducirse o el rendimiento supera el límite acordado. Si no hay escena o exportación disponible, marca el candidato **no evaluado**, no aceptado. Un DSL de estados de pliegue sigue siendo una hipótesis consultiva hasta que una comparación controlada supere el camino más sencillo del manifiesto.

### Ejercicio 5: aplicar la regla de decisión

Supón que un futuro candidato tiene hashes y capturas completos, ángulos `+60°` y `−59°` y tiempo por fotograma medido aceptable. Tres de cuatro revisores identifican la dependencia frente a cuatro de cuatro con texto plano. Su clic `e1` también devuelve la etiqueta `e2` una vez en diez reproducciones. ¿Qué decisión corresponde y qué comprobantes hacen falta?

> **Respuesta:** Rechaza o revisa el candidato según la regla declarada. Pasan ángulos y coste, pero la comprensión es inferior a la referencia y el vínculo de `e1` es incorrecto en una reproducción. Conserva hashes del GLB fuente y de salida, revisión de escena, manifiesto auxiliar, registros de importación, capturas brutas, diez trazas de eventos, respuestas individuales y muestras de tiempo por fotograma. Corrige el vínculo y la explicación visual y repite la misma comparación. Las cifras inventadas son una fixture de ejercicio, no una medición del proyecto.

## Pruebas y límites

- El plan y el anfitrión GA enlazados establecen una vía de visualización propuesta; no establecen un observatorio plegado en funcionamiento. Los scripts e informes Learn enlazados establecen ejemplos de modelado, topología, UV y glTF en otros recursos; no validan esta fixture.
- Todos los ángulos, recuentos de revisores, resultados de escena y significados de política de los ejercicios son sintéticos. No se afirma ejecución de Blender o Godot, análisis cultural, revisión humana, intento de estudiante ni comprobación pública. El ciclo anterior del original inglés tampoco afirmaba una traducción; este borrador en español requiere aprobación de una persona que domine el español.
- El umbral de limpieza de VC-005 puede importar más adelante, pero conservar solo triángulos no conserva ID, signo y significado de un pliegue. Este curso mantiene separadas esas comprobaciones.
