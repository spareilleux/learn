---
title: Pruebas para un puente de observatorio entre Godot y React
description: Pruebas para un puente de observatorio entre Godot y React — Computación visual
sidebar:
  label: VC-002 · Pruebas para un puente de observatorio entre Godot y React
  order: 2
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/visual-computing/es/vc-002-godot-react-bridge-evidence.es.md
---

:::note[Streeling University]
**VC-002** · Pruebas para un puente de observatorio entre Godot y React · intermedio · 35 minutos

Generado por el departamento *Computación visual* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/visual-computing/es/vc-002-godot-react-bridge-evidence.es.md) · [Mi diario](../../journal/)

Requisitos previos: [VC-001](../../visual-computing/vc-001-accessible-fretboard-paths/)
:::

> **Alcance del borrador y las traducciones.** El texto técnico siguiente es un borrador fechado. Las menciones históricas de traducciones, integración en Learn o comprobaciones de publicación pendientes corresponden a aquella etapa; este [registro de traducción](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/locale-completion-2026-10-22/README.md) documenta los borradores actuales y las comprobaciones realizadas. Los ensayos de ejecución no realizados siguen pendientes. Aún faltan la revisión humana del contenido y del idioma, y la prueba con un estudiante.

> **Departamento de Computación Visual** | Nivel: intermedio | Duración estimada: 35 minutos | Estado: borrador en español; pendientes la revisión del contenido, una prueba con un estudiante, la revisión lingüística humana y la revisión previa a la publicación

## Objetivos

Después de esta lección podrás:

- Separar un host de iframe en React, una escena Godot planificada y un observatorio 3D en ejecución verificada.
- Rastrear los mensajes `godot:ready` y `godot:node-clicked` a través de la comprobación de fuente y los callbacks del host.
- Escribir un contrato medible de disponibilidad y fuente de clics con una fixture fija y una futura comprobación en directo.
- Indicar exactamente qué puede y qué no puede demostrar la lectura del código fuente sobre una exportación web o tecnología de renderizado.

## La pregunta del proyecto

Una tarjeta de observatorio en GA ofrece una vista Godot 3D. Un compañero dice: «El puente React está versionado, así que la escena Godot está lista; la ruta de clics 3D funciona». ¿Qué pruebas justificarían esa afirmación?

En la revisión GA [`dc2e74c`](https://github.com/GuitarAlchemist/ga/tree/dc2e74cbd992a298f67efb928b5b3754615e1924), [`GodotScene.tsx`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/ReactComponents/ga-react-components/src/components/PrimeRadiant/GodotScene.tsx) implementa un host React con vistas iframe en panel y pantalla completa. Su `src` predeterminado es `/godot/index.html`. Declara tipos TypeScript de mensajes, escucha eventos de navegador `message`, gestiona `godot:ready` y `godot:node-clicked` y expone callbacks. El [plan versionado de integración Godot](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/docs/plans/parked/2026-03-28-feat-godot-integration-plan.md) marca como realizado el trabajo de puente e integración de Phase 1, pero deja sin marcar la escena Godot de gravedad constitucional y la exportación web WASM. El plan está guardado en `docs/plans/parked/` pese a su antigua cabecera «activo»; ninguna etiqueta demuestra ejecución.

Una búsqueda en las rutas seguidas de este árbol GA fijado no encontró escenas `.gd` ni `.tscn`, `godot/index.html`, exportaciones `.wasm` ni archivos nombrados para DLSS. Es un hallazgo acotado al repositorio, no una prueba sobre otras ramas, la máquina de un desarrollador, recursos desplegados ni todos los nombres posibles de implementación. Una ruta de renderizado DLSS derivada de un fork queda fuera del puente inspeccionado y sigue sin verificar. El iframe del componente y su texto de alternativa no demuestran que exista o se ejecute una exportación Godot.

### Ejercicio práctico 1: clasificar las pruebas

Clasifica cada afirmación como **respaldada por el código fuente**, **planificada o sin verificar** o **requiere ejecución en directo**: (a) React declara un iframe con valor predeterminado `/godot/index.html`; (b) la escena de gravedad Godot renderiza nodos de políticas; (c) pulsar un nodo Godot real selecciona el registro React correspondiente; (d) el DLSS derivado de un fork mejora la imagen del observatorio.

> **Respuesta:** (a) está respaldada por el componente React fijado. (b) es una escena planificada con trabajo sin marcar en el plan fijado. (c) requiere una escena o exportación real y una traza observada de callbacks; la declaración del host por sí sola no puede demostrarlo. (d) no está verificada en el árbol inspeccionado y necesita una implementación identificada por separado y una medición.

## 1. Definir un pequeño contrato de puente

La unión TypeScript de mensajes salientes del host incluye `{ type: 'godot:ready' }` y `{ type: 'godot:node-clicked', nodeId: string }`. Su manejador de mensajes compara `ev.source` con el `contentWindow` del iframe montado **cuando existe la ref del iframe**. Después comprueba que `ev.data.type` sea una cadena y elige una rama según los dos tipos de mensajes. Un `godot:ready` de fuente coincidente activa una ref interna de disponibilidad, elimina el estado de carga e invoca `onReady`. Un `godot:node-clicked` de fuente coincidente invoca `onNodeClick` con `msg.nodeId`.

Son comportamientos del código fuente, no un contrato completo de confianza o disponibilidad. El manejador no compara `ev.origin`, no valida `nodeId` en ejecución ni exige estar listo antes de aceptar un clic. Si falta la ref del iframe, se omite la comparación de fuente. La aserción TypeScript `as GodotOutboundMessage` no valida un evento entrante del navegador. Los mensajes salientes usan `postMessage(msg, '*')`; un futuro despliegue entre orígenes necesita una decisión explícita sobre el origen de destino. Para la fixture de esta lección, supone que el iframe está montado y ambos callbacks instalados, por lo que se aplica la comparación de fuente.

### Ejercicio práctico 2: comprobar el remitente

Una ventana distinta del iframe montado envía `{ type: 'godot:ready' }`. Después el iframe montado envía el mismo mensaje. ¿Cuál invoca `onReady` bajo los supuestos de la fixture? ¿La coincidencia de `ev.source` por sí sola demuestra que el contenido es válido o que se renderizó la escena?

> **Respuesta:** El manejador rechaza el mensaje de la ventana ajena por la comparación de fuente. El mensaje del iframe montado activa la ref de disponibilidad e invoca `onReady`. La igualdad de fuente es solo una comprobación: el manejador no inspecciona el origen ni valida los campos del contenido en ejecución, y un mensaje de listo no demuestra que la escena renderizara un fotograma.

## 2. Seguir una fixture sintética fija de mensajes

Es una **fixture de razonamiento**, no una prueba de navegador ni una ejecución Godot observada. Sea `F` el `contentWindow` del iframe montado y `X` otra ventana. Empieza con `readyRef = false`, `loading = true` y los contadores de callbacks a cero. Entrega estos eventos al manejador del host en orden:

| Paso | Fuente | Evento o reloj | Qué hace el manejador fijado |
|---|---|---|---|
| 1 | X | `{ type: 'godot:ready' }` | Lo ignora porque la fuente difiere de F |
| 2 | F | `{ type: 'godot:node-clicked', nodeId: 'belief-7' }` | Llama a `onNodeClick('belief-7')` incluso antes de estar listo |
| 3 | F | `{ type: 'godot:ready' }` | Activa disponibilidad, elimina carga y llama a `onReady` |
| 4 | F | `{ type: 'godot:ready' }` otra vez | Vuelve a llamar a `onReady`; no hay deduplicación programada |
| 5 | F | `{ type: 'godot:node-clicked', nodeId: 'belief-8' }` | Llama a `onNodeClick('belief-8')` |
| 6 | reloj | Se activa el timeout de quince segundos | Encuentra disponibilidad verdadera y no cambia la alternativa |

La fixture predice **dos callbacks de disponibilidad y dos de clic**, incluido un clic antes de estar listo. No afirma que Godot emitiera realmente ninguno de esos mensajes. Si no llega ningún mensaje de listo, el timeout oculta el indicador de carga tras 15 segundos sin activar la ref de disponibilidad ni indicar error; «indicador desaparecido» no significa «escena lista». El modo panel del host muestra inicialmente la pestaña Builder, así que el iframe puede no montarse hasta seleccionar la pestaña Viewer.

### Ejercicio práctico 3: contar callbacks

Usando solo la tabla y el manejador fijado, enumera la secuencia de callbacks. ¿Qué debería evitar deducir del paso 6 un panel de observatorio?

> **Respuesta:** Los callbacks son `onNodeClick('belief-7')`, `onReady()`, `onReady()` y después `onNodeClick('belief-8')`. El paso 1 no produce ninguno. El timeout del paso 6 no produce ninguno porque ya está listo. En una ejecución sin evento de listo, el timeout puede eliminar igualmente el indicador, por lo que un panel no debe deducir disponibilidad de su desaparición.

## 3. Hacer medible el comportamiento deseado

Un contrato futuro de producto puede ser más estricto que el manejador actual. Para un iframe montado y una generación de carga, propón: aceptar disponibilidad solo de la fuente esperada y el origen permitido con contenido válido; contar **una** transición de disponibilidad; aceptar un clic solo tras esa transición, de la misma fuente y origen, con un `nodeId` conocido no vacío; entregar cada clic intencional a React **exactamente una vez**. Una recarga inicia una nueva generación y reinicia los contadores. Es una regla propuesta de aceptación, no una descripción del código actual. Los pasos 2 y 4 de la fixture sintética incumplirían sus condiciones de clic previo a disponibilidad y disponibilidad duplicada.

Cuando existan una escena Godot real y una exportación web, una comprobación del puente en directo podría usar un **host de pruebas dedicado que mantenga montado el iframe durante una generación de carga**. Registra el SHA de compilación y el navegador, espera un evento de listo, realiza **20 clics en nodos conocidos** y compara los 20 identificadores esperados con los 20 de callbacks, en orden y sin duplicados. El [padre Prime Radiant fijado](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/ReactComponents/ga-react-components/src/components/PrimeRadiant/ForceRadiant.tsx) cambia a detalle tras un clic de panel reconocido y cierra la vista completa después de su callback de clic; una ejecución de 20 clics en ese host de producto necesitaría reabrir y obtener un nuevo estado listo para cada clic. Inyecta mensajes sintéticos de fuente ajena y previos a disponibilidad en el harness dedicado y exige **cero callbacks de fuente ajena** y **cero callbacks de clic previos a disponibilidad**; reenvía listo y exige que no haya segunda transición. Registra fuente del mensaje, origen, resultado de validación del contenido, número de callbacks y una observación de fotograma renderizado o captura de pantalla. Una captura por sí sola no demuestra el enrutamiento de clics; una traza de callbacks por sí sola no demuestra que la escena Godot se renderizara correctamente. Hasta tener esas observaciones, el contrato es una propuesta de prueba.

### Ejercicio práctico 4: comprobar la disponibilidad

Un ensayo en directo informa de que el indicador de carga desapareció tras 15 segundos, pero no registra ningún mensaje `godot:ready`. ¿Puede contar la escena como lista? Nombra otra observación necesaria.

> **Respuesta:** No. El timeout del host elimina la carga sin establecer disponibilidad. Registra un evento válido de listo del iframe montado bajo las reglas elegidas de origen y contenido, y observa un fotograma renderizado u otra señal explícita de escena lista antes de afirmar que funciona la vista 3D.

### Ejercicio práctico 5: fijar una condición de éxito

Una futura prueba con host dedicado envía 20 clics conocidos después de estar listo, recibe 19 callbacks React coincidentes y obtiene uno de una ventana ajena. ¿Supera el contrato propuesto? Indica los recuentos esperados y observados e identifica un artefacto necesario antes de ejecutarla.

> **Respuesta:** No. El contrato exige 20/20 callbacks ordenados, exactamente una vez cada uno, y cero callbacks de fuente ajena; el ensayo tiene 19/20 callbacks conocidos y uno de fuente ajena. Se necesitan una escena Godot versionada y una exportación web servida en la URL del iframe antes de que esto pueda ser una prueba de escena en directo. Conserva el SHA de compilación y la traza de eventos para diagnosticar los callbacks ausentes y ajenos.

## Ideas clave

- Un host React versionado demuestra un host y un manejador, no una escena Godot en ejecución.
- Mensajes de listo, indicadores de carga, fotogramas renderizados y callbacks de clic son observaciones independientes.
- Fuente, origen, estructura del contenido, generación de carga y recuentos de callbacks forman parte de un contrato medible de puente.
- El manejador actual acepta clics previos a disponibilidad y mensajes repetidos de listo en la fixture fija de razonamiento; una regla de producto más estricta necesita implementación y pruebas en directo.
- Una fase sin marcar de un plan o un archivo ausente en un árbol fijado limita la afirmación, no es una declaración universal sobre todos los entornos.

## Pruebas del proyecto y límites

- GA fijado: [`GodotScene.tsx`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/ReactComponents/ga-react-components/src/components/PrimeRadiant/GodotScene.tsx), [padre Prime Radiant](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/ReactComponents/ga-react-components/src/components/PrimeRadiant/ForceRadiant.tsx) y [plan aparcado de integración Godot](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/docs/plans/parked/2026-03-28-feat-godot-integration-plan.md). La inspección de fuentes cubrió este árbol fijado; no ejecutó la escena ni auditó un despliegue.
- [VC-001](../../visual-computing/vc-001-accessible-fretboard-paths/) aborda otro requisito: una vista 3D debe conservar la información útil y las acciones disponibles en rutas de puntero, teclado y lector de pantalla. El contrato de puente aquí no completa esa comprobación de accesibilidad.
- La fixture de seis pasos y el umbral de aceptación de 20 clics son artefactos didácticos y de propuesta de prueba. No se ha verificado para esta lección ninguna ejecución Godot, exportación WASM, implementación DLSS derivada de un fork, revisión del contenido, intento de estudiante, localización ni lectura pública.

*Investigación: `visual-computing-2026-10-11-002`. Solo borrador en español; pendientes revisión humana del contenido, lingüística y con un estudiante, y publicación.*
