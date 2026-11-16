---
module_id: vc-004-godot-observatory-capture-gate
department: visual-computing
course: "Una condición de captura para el observatorio de Godot"
level: intermediate
prerequisites: [vc-002-godot-react-bridge-evidence]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
research_cycle: visual-computing-2026-10-11-004
version: "0.1.0"
---

# Una condición de captura para el observatorio de Godot

> **Alcance del borrador y las traducciones.** El texto técnico siguiente es un borrador fechado. Las menciones históricas de traducciones, integración en Learn o comprobaciones de publicación pendientes corresponden a aquella etapa; este [registro de traducción](../../../../code/streeling/evidence/locale-completion-2026-10-22/README.md) documenta los borradores actuales y las comprobaciones realizadas. Los ensayos de ejecución no realizados siguen pendientes. Aún faltan la revisión humana del contenido y del idioma, y la prueba con un estudiante.

> **Departamento de Computación Visual** | Nivel: intermedio | Duración estimada: 35 minutos | Estado: borrador en español; revisiones de materia, estudiante, localización y publicación pendientes, incluida la aprobación de una persona que domine el español

## Objetivos

Después de esta lección, podrás indicar qué partes del observatorio Godot de GA están respaldadas por las fuentes, especificar una captura reproducible de antes y después de un cambio de encuadre, calcular una zona visual segura y comprobar repetibilidad, y tomar una decisión de aceptación acotada que incluya imágenes y trazas de interacción.

## La pregunta del proyecto

Un diseñador propone mover la cámara del observatorio para que se lean mejor la estructura central de gobernanza y los nodos de política. Una captura parece mejor en su equipo. ¿Basta para sustituir la cámara de referencia? ¿Qué debe capturar, medir y conservar un revisor para comprobar después la decisión?

El [plan de integración de Godot en `dc2e74c`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/docs/plans/parked/2026-03-28-feat-godot-integration-plan.md) fijado de GA propone una escena de gravedad constitucional con nodos de política en órbita en `Apps/ga-godot/` (Phase 2), una exportación web (Phase 4) y un ciclo de captura a crítico (Phase 5). Todas esas tareas están **sin marcar** en el plan fijado. El [anfitrión React `GodotScene.tsx`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/ReactComponents/ga-react-components/src/components/PrimeRadiant/GodotScene.tsx) declara modos de panel y pantalla completa, usa `/godot/index.html` como URL predeterminada de iframe y maneja mensajes `godot:ready` y `godot:node-clicked`. Esas declaraciones respaldan una futura vía de visualización e interacción, no una escena renderizada observada ni un sistema de captura existente. El plan está bajo `docs/plans/parked/` pese a su antiguo encabezado «activo»; ninguna etiqueta demuestra disponibilidad en ejecución.

El commit GA examinado no tiene una escena Godot `.tscn`, exportación web ni resultado de captura verificados para esta lección. Un prototipo local independiente sin commit fuente versionado no proporcionaría una cita estable, por lo que no respalda las cifras siguientes. La lección diseña una evaluación **antes** de poder aprobar ese cambio de escena. Todas las coordenadas, recuentos y resultados de la fixture de ejercicio son sintéticos. Aquí no se ejecutó Godot, navegador, crítico de capturas ni escalador.

## 1. Nombrar el cambio y fijar sus controles

Una comparación justa necesita una variable independiente declarada. Aquí es el **encuadre de cámara** de una futura escena Godot. Mantén fijos contenido de escena, instantánea de datos de gobernanza, ID de nodos, viewport, escala de pantalla, renderizador, iluminación, ajustes de calidad y revisión de compilación al capturar las poses de referencia y candidata. Registra cada pose como posición, rotación, campo de visión o proyección y objetivo. Si la escena se anima, congela un instante o fotograma nombrado y desactiva cualquier semilla aleatoria no controlada. Comparar dos capturas donde cambian cámara e iluminación no permite aislar qué cambio hizo más visible una arista. Si el experimento es de iluminación, modo de renderizado o escalado, mantén fija la cámara y registra esa variable expresamente. Las comparaciones de escalado deben registrar resolución interna de renderizado y de salida; una imagen grande por sí sola no demuestra igual coste de renderizado.

Para una futura ejecución, el manifiesto debería indicar commit GA, commit del proyecto Godot, hash de compilación exportada, instantánea de escena/datos, renderizador y versión Godot, pose de cámara, viewport y escala del dispositivo, fotograma/tiempo y versión del comando de captura. Da a cada PNG una fila, una marca temporal y un hash de contenido. Captura los modos React de **panel** y **pantalla completa** por separado porque el anfitrión declara ambos; selecciona la pestaña Viewer del panel, pues su pestaña inicial Builder no monta la iframe. No supongas que ninguno cargue actualmente una exportación Godot. El sistema de captura propuesto debería guardar PNG brutos y un manifiesto legible por máquina; un montaje seleccionado ayuda a discutir, pero no sustituye los fotogramas originales. Un revisor humano podrá examinar el cambio declarado contra una referencia estable sin depender de recuerdos.

### Ejercicio 1: clasificar las pruebas

Clasifica como **respaldado por la fuente**, **planificado** o **requiere una ejecución**: (a) el anfitrión declara una iframe con `/godot/index.html` por defecto; (b) la escena de gravedad constitucional se capturó tres veces en el mismo navegador; (c) el plan fijado incluye un ciclo de captura a crítico; (d) una nueva pose mejora la legibilidad de los nodos.

> **Respuesta:** (a) está respaldado por `GodotScene.tsx`. (c) está planificado en la Phase 5 sin marcar. (b) requiere exportación real, navegador y tres capturas guardadas; aquí no se observó nada de eso. (d) requiere una tarea de legibilidad definida y datos comparativos. Una entrada del plan o una cadena fuente de iframe no aporta esas observaciones.

## 2. Usar imágenes para probar una afirmación visual

Supón que la futura escena tiene tres nodos objetivo conocidos, A, B y C, visibles desde tres puntos de vista nombrados. Una cámara candidata debería mantener sus marcas dentro de un **rectángulo seguro** que deje cinco por ciento de anchura y altura de salida en cada borde. Ese margen es un umbral propuesto del proyecto, no un valor por defecto de Godot ni una norma de accesibilidad. A 1280 × 720 píxeles, el intervalo x seguro es `[64, 1216]` y el y `[36, 684]`. Debe caber toda la caja delimitadora anotada del objetivo, no solo su centro. La anotación debería incluir ID y coordenadas del rectángulo en el PNG bruto de salida. En cada vista nombrada, captura tres fotogramas repetidos con iguales valores de manifiesto y calcula el mayor cambio de coordenada de cada borde entre repeticiones. Exige como máximo **dos píxeles** de deriva. Es un umbral propuesto de repetibilidad, no una medición del proyecto.

La zona segura detecta recortes y acumulación junto a los bordes; no establece que una etiqueta sea legible, un color distinguible o las señales de profundidad fieles. Una tarea humana propuesta consiste en identificar A, B y C sin superposición de respuestas, usando esta solo para puntuar. Registra errores y motivos y compara candidato y referencia con la misma tarea y condiciones. Un crítico de capturas puede señalar recortes sospechosos o etiquetas ilegibles, pero su puntuación necesita calibrarse contra resultados de tarea antes de ser condición de aceptación. Un umbral de diferencia de píxeles entre referencia y candidato sería inadecuado para un movimiento deliberado de cámara: la diferencia demuestra cambio, no mejora. Usa diferencias entre repeticiones para probar estabilidad y resultados de tareas para probar utilidad.

### Ejercicio 2: controlar la comparación

Dos capturas tienen los mismos datos de nodos y tamaño de salida, pero la candidata cambia pose de cámara e iluminación y su PNG carece de hash de compilación. ¿Permite aislar el efecto de la cámara? Nombra las reparaciones mínimas.

> **Respuesta:** No. Fija compilación de escena/exportación e instantánea de datos, registra hash y ajustes de cámara y mantén fijos iluminación y demás controles al comparar cámaras. Guarda imágenes brutas y manifiesto. Evalúa la iluminación por separado con cámara fija. Sin esos controles, un nodo más claro podría deberse a cualquiera de los cambios o a una compilación desconocida.

### Ejercicio 3: calcular la zona segura

En una salida **sintética** de 1280 × 720, las cajas candidatas son A `(80, 50)–(180, 130)`, B `(60, 50)–(160, 130)` y C `(90, 40)–(190, 120)`. ¿Cuáles cumplen la regla propuesta del cinco por ciento y cuál es el menor desplazamiento horizontal que introduciría el borde izquierdo de B?

> **Respuesta:** Los límites seguros son x `64–1216` e y `36–684`. A y C caben. B falla porque su borde izquierdo es `60 < 64`; moverlo al menos cuatro píxeles a la derecha lo pondría en 64. Mover una cámara real puede desplazar todas las marcas, así que habría que capturar y comprobar otra vez las tres cajas. Este cálculo no procede de una imagen Godot observada.

## 3. Comprobar repetibilidad antes de juzgar mejora

Los mismos ajustes deberían producir fotogramas comparables. Para objetivos estáticos, calcula deriva de bordes de cada grupo de tres repeticiones; conserva las tres imágenes en vez de elegir la mejor. Si hay movimiento intencional, define un paso fijo de simulación o compara un punto estable. Si no puede controlarse, informa de una distribución de capturas repetidas en vez de afirmar repetibilidad al píxel. Registra también carga y comportamiento de fotogramas: un ajuste que mejora encuadre pero vuelve inutilizable la exportación web no supera la condición completa. Mide tiempo por fotograma en el mismo dispositivo y navegador durante una ejecución especificada, con mediana y valores de cola de distribución; no lo deduzcas del tamaño de imagen ni de la suavidad aparente de una grabación. La lección no fija un presupuesto de rendimiento sin medir para la futura exportación.

El callback de disponibilidad del anfitrión React puede ayudar a un futuro sistema a saber cuándo la iframe informa de que está lista, pero el manejador fijado acepta mensajes repetidos y no demuestra un fotograma renderizado. Compara la fuente del mensaje cuando existe la referencia de iframe; no valida origen ni `nodeId` en ejecución. Como detalla [VC-002](vc-002-godot-react-bridge-evidence.md), una futura comprobación debería registrar un fotograma real y clics intencionales, no solo que desapareció el indicador de carga. Las pruebas visuales y de interacción ocupan columnas separadas.

### Ejercicio 4: probar la repetibilidad de capturas

En el borde izquierdo de un objetivo, tres capturas repetidas **sintéticas** dan x `80`, `81` y `84`. ¿Cumplen la deriva máxima propuesta de dos píxeles? ¿Qué debería hacer el revisor antes de comparar calidad visual con la referencia?

> **Respuesta:** No. Máximo menos mínimo es `84 − 80 = 4` píxeles, más de dos. Conserva los tres PNG, comprueba si cámara, viewport, tiempo de escena, animación y datos estaban realmente fijos y recaptura tras identificar la causa no controlada. Elegir solo la imagen x = 80 ocultaría la inestabilidad.

## 4. Redactar una condición capaz de rechazar una captura bonita

La condición propuesta para una futura exportación Godot versionada tiene etapas ordenadas. Primero, establece procedencia de compilación, exportación servida, evento de disponibilidad **y** un fotograma renderizado capturado; si no, la comparación visual es **no evaluable**. Segundo, recoge PNG brutos de referencia y candidato en panel y pantalla completa para vistas nombradas, tres repeticiones por vista con manifiestos completos. Tercero, exige todas las cajas conocidas dentro del rectángulo seguro y deriva de cada objetivo estático igual o inferior a dos píxeles. Cuarto, ejecuta una tarea de identificación sobre los mismos ID conocidos y exige que el candidato no sea peor que la referencia. Quinto, en un anfitrión de pruebas dedicado con iframe montada, exige **20/20 clics intencionales conocidos** entregados a los ID React previstos en orden y **cero** callbacks de mensajes inyectados desde fuentes ajenas. Este último umbral es una comprobación propuesta cuando exista una exportación real, no un resultado de la lección; un anfitrión que cierre o cambie de vista al pulsar necesita una traza de reentrada aparte. Registra fallos y aciertos y conserva el registro bruto de eventos junto a las imágenes.

La condición es deliberadamente conjuntiva: una etapa fallida bloquea la decisión. No certifica calidad artística ni accesibilidad. [VC-001](vc-001-accessible-fretboard-paths.md) aporta un requisito separado de acceso por teclado y lector de pantalla. Una propuesta de modo de renderizado o escalado también necesitaría su matriz de dispositivos y presupuesto medido de tiempo por fotograma; las fuentes fijadas de GA no demuestran un fork de DLSS, renderizador concreto ni escalador. Aprobar una cámara a partir de una tabla sintética sería un error de categoría. La tabla solo sirve para practicar la lógica de aceptación.

| Candidato hipotético | Compilación, disponibilidad, fotograma, capturas brutas | Cajas seguras y deriva | Identificación frente a referencia | Traza de clics dedicada |
|---|---|---|---|---|
| X | Completos | Borde izquierdo B 60; deriva 4 px | Igual | 20/20; ajenos 0 |
| Y | Completos | Todas seguras; deriva 2 px | Igual | 19/20; ajenos 0 |
| Z | Completos | Todas seguras; deriva 2 px | Igual | 20/20; ajenos 0 |

### Ejercicio 5: decidir sin seleccionar solo lo favorable

Aplica la condición a X, Y y Z. ¿Qué candidato hipotético supera las comprobaciones de la **fixture**? ¿Qué pruebas adicionales hacen falta antes de aceptar un cambio real de cámara del observatorio?

> **Respuesta:** X falla zona segura y repetibilidad pese a su traza perfecta. Y falla el requisito de 20/20 clics pese a sus imágenes aceptables. Z supera todas las columnas sintéticas enumeradas. Ninguno es un resultado observado de Godot. Una decisión real sigue necesitando escena/exportación versionada, capturas brutas y manifiestos reproducibles, resultados reales de tareas y trazas, revisión de accesibilidad y significado visual y cualquier umbral acordado de rendimiento del dispositivo.

## Ideas clave y límites de las pruebas

- Un plan fijado puede motivar un protocolo sin demostrar que funcionen la escena, exportación o crítico previstos.
- Para comparar cámaras, varía cámara y mantén fijos escena, datos, renderizador, iluminación, viewport y tiempo de captura. Registra entradas y conserva imágenes brutas.
- Los cálculos de zona segura y deriva hacen revisable una captura; el éxito en tareas y las trazas responden a preguntas distintas. Una captura atractiva no los sustituye.
- Los cinco ejercicios usan cajas y resultados inventados. Los umbrales de cinco por ciento, dos píxeles y 20/20 clics son criterios propuestos, no referencias GA medidas.
- Aquí no se afirma captura activa de Godot, alimentación de datos IX/Gaia, medición de escalado, revisión humana de materia, prueba con estudiantes ni publicación. El ciclo anterior del original inglés tampoco afirmaba una traducción; este borrador en español requiere aprobación de una persona que domine el español.

*Investigación: `visual-computing-2026-10-11-004`. Borrador en español; revisión y publicación pendientes.*
