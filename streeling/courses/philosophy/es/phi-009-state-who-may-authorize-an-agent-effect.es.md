---
module_id: phi-009-state-who-may-authorize-an-agent-effect
department: philosophy
course: "Precisar quién puede autorizar un efecto de agente"
level: intermediate
prerequisites: ["phi-002-when-is-an-advisory-decision-justified", "phi-005-test-idempotence-beyond-replayed-values"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Precisar quién puede autorizar un efecto de agente

> Borrador pendiente de revisión humana. Los casos fijos siguientes son modelos matemáticos elaborados tras consultar las fuentes; no son mediciones nuevas del proyecto. Siguen pendientes los dictámenes técnicos, artesanales, lingüísticos y de aprendizaje. Para esta lección no se ejecutó ningún motor de escenas, muestra física, GPU, ejecutor de políticas ni sesión con estudiantes.

## Pregunta del proyecto

Un resultado consultivo Demerzel indica allow y un worker dispone de credenciales capaces de modificar un repositorio. ¿Quién autorizó el efecto? El esquema fijado describe explícitamente una salida consultiva y prohíbe la mutación por esa decisión. Capacidad, recomendación y autorización son proposiciones distintas. Modelamos un control propuesto para rechazar que una comprobación de herramienta satisfactoria implique permiso de actuar.

[Requisito previo: phi-002-when-is-an-advisory-decision-justified](../../philosophy/en/phi-002-when-is-an-advisory-decision-justified.md); [Requisito previo: phi-005-test-idempotence-beyond-replayed-values](../../philosophy/en/phi-005-test-idempotence-beyond-replayed-values.md)

## Leer el alcance antes de calcular

Lea el requisito previo y el documento del proyecto antes de calcular. Distinga las afirmaciones procedentes del código inspeccionado, los resultados registrados anteriormente y las consecuencias exclusivas de las premisas siguientes. Un comentario del código, una respuesta preparada y una observación ejecutada aportan evidencias distintas. Conserve la fecha original y todo control fallido o inconcluso al resumir un documento anterior. La referencia manual consiste en un cálculo breve en papel y una tabla de ubicaciones en las fuentes; un agente puede ayudar a localizar una definición, pero su resumen debe contrastarse con ella. Esta comparación finita no requiere un lenguaje ni una automatización nuevos.

Suponga que un efecto requiere una instrucción aplicable de un responsable autorizado, un alcance que coincida con el efecto y una instrucción aún válida al actuar. El actor también necesita capacidad, pero esta no aporta ninguna premisa de autorización ausente. El modelo booleano omite autenticación, carreras de revocación y ejecución: solo ayuda a razonar. Vincule la autoridad al repositorio, efecto y revisión reales, no a una etiqueta favorable. Una autorización para redactar un curso no cubre necesariamente publicación o fusión. La confianza del asesor no cambia al responsable ni el alcance de la instrucción.

## Caso fijo y supuestos

```text
permit=principal_authorized AND scope_matches AND still_valid
may_execute=permit AND capability
cases=[
 {"name":"advice_only","principal_authorized":false,"scope_matches":true,"still_valid":true,"capability":true},
 {"name":"wrong_scope","principal_authorized":true,"scope_matches":false,"still_valid":true,"capability":true},
 {"name":"revoked","principal_authorized":true,"scope_matches":true,"still_valid":false,"capability":true},
 {"name":"declared_permit","principal_authorized":true,"scope_matches":true,"still_valid":true,"capability":true}
]
may_execute_values=[false,false,false,true]
control_no_capability: permit=true; may_execute=false
```

## Ejercicios resueltos

### Ejercicio 1

Evalúe el caso de consejo únicamente.

> **Respuesta:** El resultado es `false`: capacidad y recomendación favorable no constituyen la instrucción de un responsable autorizado.

### Ejercicio 2

Evalúe los casos de alcance incorrecto y revocación.

> **Respuesta:** Ambos son `false`. Una identidad correcta con efecto fuera del alcance, o una instrucción ya no válida, falla el control declarado.

### Ejercicio 3

¿Qué caso construido permite ejecutar en el modelo?

> **Respuesta:** Solo el caso declared-permit da `true`. Sus premisas booleanas son ficticias, no prueba de una autorización real para modificar el proyecto.

### Ejercicio 4

Quite la capacidad a un caso autorizado. ¿Qué distinción queda?

> **Respuesta:** El permiso sigue siendo `true`, mientras la posibilidad de ejecutar es `false`. El modelo distingue autoridad y capacidad práctica en ambos sentidos.

### Ejercicio 5

¿Puede copiarse allow a un campo de permiso de mutación?

> **Respuesta:** No. El contrato fijado es consultivo y prohíbe mutaciones. Todo efecto real exige su proceso de autorización aplicable y evidencia actual; esta lección no ejecuta efectos.

## Tarea con consulta de fuentes

Lea la descripción de decisión del esquema. Prepare manualmente una tabla actor-efecto-autoridad para una publicación Learn hipotética, sin ejecutarla. Pida clasificar los casos y conserve el razonamiento. Tratar una recomendación como instrucción autorizada refuta la afirmación de autoridad.

Resuelva la tarea ocultando las respuestas. Conserve las respuestas originales, los cálculos intermedios, las ubicaciones en las fuentes, las dudas y toda ayuda recibida, incluso una pista, un término traducido o una sugerencia de un agente. Después compárelas con las respuestas preparadas y registre las correcciones sin sustituir el intento original. Redacte una nota breve con la afirmación, sus supuestos, el cálculo, el control negativo y la próxima observación que podría refutarla. Un resultado correcto sin unidades ni identidad de la fuente no basta para demostrar transferencia. El expediente contiene cinco criterios preparados para el estudiante; sus decisiones permanecen null hasta disponer de un intento real y una revisión autorizada. Superar estos cálculos solo acreditaría competencia en este caso declarado. No acreditaría un adaptador implementado, un proceso material satisfactorio, un renderizador más rápido ni mejoras de aprendizaje en el proyecto. Compare la nota asistida con la referencia manual: si la ayuda oculta un supuesto o elimina un rechazo, corrija la nota antes de proponer cambios de método.

## Fuentes y diario de validación

- [Registro del proyecto](../../../../code/streeling/evidence/representation-release-2026-10-22/phi002-schema-replay.json)
- [Fuente primaria](https://github.com/GuitarAlchemist/Demerzel/blob/9ba9a29f6424ac8c1a6654c9b979b282a8cf216f/schemas/advisory-decision.schema.json)
- [Expediente de evidencias fijas](../../../../code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
