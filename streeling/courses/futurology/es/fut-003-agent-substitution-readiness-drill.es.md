---
module_id: fut-003-agent-substitution-readiness-drill
department: futurology
course: Ensayar un cambio de agente sin perder las pruebas
level: early-intermediate
prerequisites: [fut-002-routing-embedder-revisit-triggers]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
research_cycle: futurology-2026-10-12-003
version: "0.1.0"
---

# Ensayar un cambio de agente sin perder las pruebas

> **Alcance de la fuente y la transferencia.** El texto técnico siguiente procede de un borrador archivado. Las menciones históricas de traducciones todavía no redactadas, de una importación o compilación pendiente en Learn corresponden a aquella etapa; este [registro de transferencia](../../../../code/streeling/evidence/representation-release-2026-10-22/README.md) documenta los borradores traducidos actuales, la importación y sus comprobaciones. Las demás experiencias indicadas como no realizadas siguen pendientes. Aún faltan la revisión humana del contenido y del idioma, y la prueba con un estudiante.

> **Alcance del utillaje histórico.** La PR Learn #170 se cerró sin fusionar el 2026-10-21. Su experimento de helper de recibos no existe en las herramientas actuales de Learn. La autoría actual de cursos EN/FR/ES reside en Learn `streeling/courses/`. El experimento histórico solo aporta pruebas en el código fuente; no demuestra ninguna revisión humana, resultado de estudiante ni pipeline actual de recibos.

> **Departamento de Futurología** | Nivel intermedio inicial | 35 minutos | Borrador en español; pendientes la revisión humana del contenido, una prueba con un estudiante y la revisión por una persona que domine el español

## Objetivos y pregunta del proyecto

Aprenderás a especificar un pequeño contrato de capacidades, evaluar un ejercicio sintético de sustitución de agente y escribir un desencadenante medible para revisar la configuración actual. **Pregunta del proyecto:** si aparece un agente o una herramienta más capaz durante el periodo pre-AGI, ¿cómo pueden GA y Streeling probarlo sin perder las pruebas que hacen que su trabajo se pueda revisar y publicar? Esta lección no predice cuándo llegará ese sistema. Trata un agente nuevo como una implementación candidata de un flujo de trabajo con salidas observables.

La [guía de ingeniería agéntica de GA en `dc2e74c`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/docs/methodology/agentic-engineering.md) recomienda mejorar el harness, mantener fronteras claras entre módulos, usar colas acotadas y hacer eficiente la revisión. Son decisiones de diseño del proyecto, no pruebas de que cualquier agente sea intercambiable hoy. [FUT-002](fut-002-routing-embedder-revisit-triggers.md) pregunta cuándo debería GA reabrir una decisión sobre su embedder de enrutamiento. Aquí ampliamos la pregunta al *agente que realiza una tarea de curso* y a las pruebas que debe entregar a la siguiente etapa. La decisión sigue siendo reversible: comparar un candidato con un conjunto pequeño y representativo de tareas antes de cambiar la lane habitual.

## 1. Especificar qué debe sobrevivir a una sustitución

Imagina que un agente redacta o edita una lección de Streeling. La siguiente persona o agente necesita saber exactamente qué fuente se comprobó, qué pruebas se ejecutaron, qué revisó un humano y qué sirve realmente el sitio público. El borrador del [generador de candidatos a revisión en Demerzel `74d425d`](https://github.com/GuitarAlchemist/Demerzel/blob/74d425dcd2ad92b4712160e3f5df7b2472c12b97/scripts/streeling_review_candidates.py) indexa blobs Git de las fuentes para el triaje; su salida no otorga expresamente aprobación humana. El [experimento histórico de recibos de Learn en `02fc08c`](https://github.com/spareilleux/learn/tree/02fc08c8f73e017412d1a623415ac4ab08645eb0) exploraba cómo llevar la identidad exacta de las fuentes a las páginas renderizadas. Ninguno de los experimentos demuestra un handoff de extremo a extremo en producción.

Una interfaz **propuesta** útil entre etapas es:

```text
Draft(source_revision, artifact)
  -> Checked(same_source_revision, named_checks)
  -> HumanReviewed(same_source_revision, reviewer_verdict)
  -> PublicReadback(same_source_revision, URL, observation)
```

Esta notación es un boceto didáctico, **no un DSL implementado ni una garantía aportada por los nombres de tipos**. Una frontera real necesita procedencia autenticada y comprobaciones reproducibles. El agente redactor no puede producir `HumanReviewed` simplemente porque emita esa palabra; el revisor y el veredicto deben proceder de un proceso humano autorizado. `PublicReadback` necesita recuperar la página desplegada en la revisión prevista. Si una lección cambia tras la revisión, el veredicto anterior no se aplica automáticamente a los bytes nuevos.

Para un ensayo acotado, exige al menos estas observaciones por tarea: identidad de la fuente de entrada; identidades de salida y destino de revisión; compilación y comprobaciones específicas identificadas; resultado de revisión humana; lectura pública anónima; tiempo transcurrido; y correcciones necesarias. Son campos candidatos de aceptación, no afirmaciones de que los agentes o el sitio actuales ya los registren todos. Un modelo más potente podría seguir necesitando otro prompt o adaptador de herramientas. El contrato trata del comportamiento verificable en la frontera, no de un razonamiento interno idéntico.

### Ejercicio práctico 1

La salida informa de `fixture-A-v2`, mientras que su entrada y el destino de revisión sintético indican `fixture-A-v1`. La compilación pasa. ¿Puede el veredicto anterior autorizar la publicación de esa salida? ¿Qué debe ocurrir después?

> **Respuesta:** No. Las identidades de fuente revisada y producida difieren, así que el veredicto anterior no cubre la salida modificada. Inspecciona el cambio y obtén un veredicto vinculado a la nueva fuente exacta antes de publicar. Una compilación superada comprueba otra propiedad.

## 2. Ejecutar un ejercicio sintético deliberadamente pequeño

La [fixture y el evaluador fijados en Demerzel `7892390`](https://github.com/GuitarAlchemist/Demerzel/tree/789239053dfeca9f044d2f893a3f277cb4ed9d8d/state/streeling/fixtures/futurology/fut-003) contienen cuatro adaptadores imaginarios y los mismos tres casos etiquetados `A`, `B` y `C`. Cada fila tiene etiquetas de fuente, salida y destino de revisión, una etiqueta de veredicto, tres comprobaciones identificadas, minutos y número de correcciones. Todas las cadenas `approved` son **valores ficticios de la fixture**, no recibos de revisión humana. La cadena `public_readback` es también una comprobación de fixture, no una recuperación del sitio. Ejecuta `python state/streeling/fixtures/futurology/fut-003/evaluate_drill.py` desde la raíz de Demerzel para reproducir la tabla.

| Adaptador sintético | Casos admisibles | Mediana de minutos, solo si pasan todos los casos | Correcciones, solo si pasan todos los casos | Motivo para conservar o rechazar |
|---|---:|---:|---:|---|
| `current` | 3/3 | 40 | 2 | Referencia de comparación |
| `portable` | 3/3 | 32 | 2 | Candidato a un ensayo mayor |
| `fast` | 1/3 | no se informa | no se informa | A cambia la identidad de la fuente; a B le falta lectura pública |
| `shortcut` | 0/3 | no se informa | no se informa | Los tres veredictos de revisión están pendientes |

El evaluador trata la identidad de la fuente, el resultado de revisión y las comprobaciones requeridas como **condiciones obligatorias**. Solo informa de una mediana para un adaptador que supera todos los casos comparables. Esto evita valorar una ejecución rápida que omitió la parte costosa de la entrega. Los mismos casos y condiciones hacen internamente coherente la comparación sintética, pero tres tareas inventadas no dicen nada de la fiabilidad real del modelo, el coste de herramientas, el valor para estudiantes ni el ahorro de tiempo esperado. La diferencia calculada, `40 - 32 = 8` minutos, es solo un resultado de fixture.

### Ejercicio práctico 2

El adaptador `fast` termina el caso B en 16 minutos. Sus etiquetas de fuente coinciden y su veredicto sintético dice `approved`. ¿Por qué se rechaza el caso B y cuántos de los tres casos de `fast` son admisibles?

> **Respuesta:** Al caso B le falta la comprobación requerida `public_readback`. El caso A tiene una discrepancia de identidad de fuente; solo C pasa. Por tanto, `fast` tiene 1/3 de casos admisibles. La fixture no demuestra que ninguna página real sea pública, ni siquiera en C.

### Ejercicio práctico 3

Calcula las medianas de `current` (`40, 44, 39`) y `portable` (`31, 32, 34`). ¿Cuál es su diferencia y qué afirmación de rendimiento seguiría sin estar justificada?

> **Respuesta:** Los valores ordenados son `39, 40, 44` y `31, 32, 34`, lo que da medianas de 40 y 32 minutos. La diferencia es de ocho minutos sintéticos. No estaría justificado afirmar un ahorro real de ocho minutos, menor coste monetario ni mayor fiabilidad sin ejecutar casos reales comparables y registrar la cadena completa de pruebas.

## 3. Elegir un desencadenante y un criterio de refutación antes de cambiar

Un **desencadenante si/entonces** es más útil que decir «cambiar cuando la IA mejore». Por ejemplo: *si un adaptador candidato supera las mismas condiciones de fuente, revisión, comprobación y lectura pública en un conjunto predeclarado de tareas reales GA/Streeling, entonces ejecutar una comparación limitada; ampliar solo si mejoran los resultados públicos aceptados y el esfuerzo de revisión sin aumentar la tasa de correcciones.* El umbral y la mezcla de tareas deben elegirse antes de examinar resultados. Se podría empezar con el mismo número de tareas de audio, DSL y publicación de cursos, pero ese reparto es un diseño de ensayo propuesto, no un tamaño de muestra validado.

El contraargumento más sólido es que una interfaz común puede ocultar diferencias importantes. Un agente puede necesitar otro contexto, permisos o prompts; forzar instrucciones idénticas puede perjudicarlo. El ensayo debería mantener **idénticas las condiciones de resultado**, permitiendo una preparación específica de cada adaptador y documentada. Registra el tiempo de preparación, revisión humana, reintentos y reparación. Si una aparente ganancia de velocidad desaparece al incluir esos costes, la sustitución no es una mejora operativa. Si un agente nuevo puede redactar más cursos, pero los veredictos humanos y las lecturas públicas correctas se mantienen, no se ha acelerado el objetivo del curso de extremo a extremo.

La alternativa más sencilla es mantener el agente actual y mejorar un verificador o un paquete de revisión. Rechaza la hipótesis de sustitución si un ensayo comparable incumple cualquier condición obligatoria, eleva la tasa de correcciones o no ofrece una ganancia sostenida de trabajo correctamente revisado y leído públicamente. Una única tarea fallida puede requerir diagnóstico en lugar de exclusión permanente; una salida sin revisar no puede promocionarse promediándola con tareas satisfactorias. El registro de decisión debería incluir el commit y el blob de fuente, la clase de tarea, la versión del evaluador, la identidad del revisor, la lectura del sitio, el entorno y el tiempo transcurrido. El coste y la latencia son mediciones que añadir, no valores que inventar.

### Ejercicio práctico 4

Supón que un agente de sustitución real redacta 20 lecciones donde el actual redacta 10 en el mismo periodo, pero las aprobaciones humanas y las lecturas públicas correctas se mantienen ambas en cuatro. ¿Qué métrica mejoró, qué resultado no lo hizo y qué trabajo podría ayudar primero?

> **Respuesta:** El rendimiento de borradores se duplicó. Las aprobaciones autenticadas y las lecturas públicas correctas siguieron en cuatro, por lo que esta observación no muestra una entrega más rápida de cursos utilizables. Examina la carga de revisión, los paquetes vinculados a fuentes, la publicación y la lectura antes de añadir más capacidad de redacción. Compara las correcciones y los resultados de estudiantes como salvaguardas.

### Ejercicio práctico 5

Escribe una decisión breve para el adaptador sintético `portable`: qué puede respaldar la fixture, qué desencadenaría un ensayo real y un resultado que refutaría el cambio.

> **Respuesta:** La fixture solo respalda que `portable` supera los tres casos *simulados* con condiciones obligatorias y tiene una mediana de 32 minutos sintéticos frente a 40 de `current`. Un ensayo real se desencadena con un candidato disponible que pueda producir las pruebas requeridas en un conjunto representativo predeclarado de tareas con las mismas condiciones de resultado. No conservar la identidad exacta de la fuente o las pruebas humanas/públicas, o no obtener una ganancia sostenida de salidas aceptadas al contar preparación y correcciones, refutaría el cambio. La fixture por sí sola no autoriza ningún cambio de producción.

## Fuentes, límites y próxima comprobación

El contexto del proyecto procede de la [guía fijada de harness y colas de GA](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/docs/methodology/agentic-engineering.md), el [generador de triaje de Demerzel](https://github.com/GuitarAlchemist/Demerzel/blob/74d425dcd2ad92b4712160e3f5df7b2472c12b97/scripts/streeling_review_candidates.py) y el [experimento histórico de recibos Learn sobre fuentes exactas](https://github.com/spareilleux/learn/tree/02fc08c8f73e017412d1a623415ac4ab08645eb0). La [entrada, el evaluador y el resultado](https://github.com/GuitarAlchemist/Demerzel/tree/789239053dfeca9f044d2f893a3f277cb4ed9d8d/state/streeling/fixtures/futurology/fut-003) son sintéticos y reproducibles en el commit `789239053dfeca9f044d2f893a3f277cb4ed9d8d`. El boceto es un contrato componible propuesto, no un DSL desplegado. Para FUT-003 no se realizó ninguna ejecución real de otro agente, veredicto humano autenticado, prueba con estudiantes, cambio de producción ni lectura pública del curso. En el ciclo inglés original, la siguiente comprobación era la revisión humana del escenario y un intento ciego de un estudiante antes de localizar o publicar la lección. Este borrador en español está pendiente de esas revisiones y de revisión lingüística humana antes de publicarse.
