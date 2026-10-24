---
module_id: phi-008-separate-a-test-oracle-from-a-specification
department: philosophy
course: "Distinguir un oráculo de prueba de una especificación"
level: intermediate
prerequisites: ["phi-001-how-to-argue-well", "phi-005-test-idempotence-beyond-replayed-values"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Distinguir un oráculo de prueba de una especificación

> Borrador pendiente de revisión humana. Los casos fijos siguientes son modelos matemáticos elaborados tras consultar las fuentes; no son mediciones nuevas del proyecto. Siguen pendientes los dictámenes técnicos, artesanales, lingüísticos y de aprendizaje. Para esta lección no se ejecutó ningún motor de escenas, muestra física, GPU, ejecutor de políticas ni sesión con estudiantes.

## Pregunta del proyecto

Un registro consultivo Demerzel supera una prueba de esquema con una lista de evidencias vacía. ¿Satisface eso el requisito más amplio de consejo justificado? La reproducción conservada registró realmente esa aceptación en la revisión fijada. Sirve para distinguir el oráculo de una prueba de la propiedad pretendida por la especificación. Un control verde solo informa sobre la condición que decide su oráculo.

[Requisito previo: phi-001-how-to-argue-well](../../philosophy/en/phi-001-how-to-argue-well.md); [Requisito previo: phi-005-test-idempotence-beyond-replayed-values](../../philosophy/en/phi-005-test-idempotence-beyond-replayed-values.md)

## Leer el alcance antes de calcular

Lea el requisito previo y el documento del proyecto antes de calcular. Distinga las afirmaciones procedentes del código inspeccionado, los resultados registrados anteriormente y las consecuencias exclusivas de las premisas siguientes. Un comentario del código, una respuesta preparada y una observación ejecutada aportan evidencias distintas. Conserve la fecha original y todo control fallido o inconcluso al resumir un documento anterior. La referencia manual consiste en un cálculo breve en papel y una tabla de ubicaciones en las fuentes; un agente puede ayudar a localizar una definición, pero su resumen debe contrastarse con ella. Esta comparación finita no requiere un lenguaje ni una automatización nuevos.

Defina un requisito construido: registro bien formado y al menos una referencia pertinente vinculada a la fuente. Un oráculo más débil solo comprueba la forma. Son predicados para la tabla didáctica, no sustitutos de la gobernanza. Un falso positivo acepta cuando el requisito es falso; un falso negativo rechaza cuando es verdadero. Copiar la implementación en la función de respuesta esperada puede producir coincidencia conservando el error compartido. Busque un contraejemplo independiente y explique la premisa evaluada. El control antiguo de campo ausente comprueba forma, pero no aporta el juicio de pertinencia que falta.

## Caso fijo y supuestos

```text
cases=["A","B","C","D"]
well_formed=[true,true,false,false]
relevant_evidence=[true,false,true,false]
spec=well_formed AND relevant_evidence
spec_values=[true,false,false,false]
weak_oracle=[true,true,false,false]
true_positive=1; false_positive=1; true_negative=2; false_negative=0
control_missing_required_field: well_formed=false
```

## Ejercicios resueltos

### Ejercicio 1

Evalúe la especificación construida en cada caso.

> **Respuesta:** El resultado es `[true,false,false,false]`. La evidencia pertinente no repara una estructura mal formada bajo esta conjunción.

### Ejercicio 2

Localice el falso positivo del oráculo débil.

> **Respuesta:** B cumple la forma pero carece de evidencia pertinente. Es el único falso positivo; los demás dan `1` verdadero positivo y `2` verdaderos negativos.

### Ejercicio 3

¿La aceptación registrada contradice el contrato limitado a la forma?

> **Respuesta:** No. El esquema permite la matriz vacía. El error consiste en tratar esa aceptación como prueba suficiente de consejo justificado en sentido amplio.

### Ejercicio 4

¿Qué prueba eliminar un campo obligatorio?

> **Respuesta:** Aporta un control negativo de forma. Se espera rechazo, pero eso no distingue un registro sin evidencias de uno justificado.

### Ejercicio 5

¿Cómo puede una prueba superada compartir el error de la implementación?

> **Respuesta:** Si ambos usan el mismo predicado debilitado, la coincidencia verifica coherencia, no el requisito pretendido. Conserve un contraejemplo independiente y la justificación de la especificación.

## Tarea con consulta de fuentes

Lea el registro y los campos obligatorios. Prepare manualmente una tabla requisito-oráculo, separando la pertinencia inventada de las comprobaciones reales del esquema. Pida justificar el resultado verde y refute cualquier generalización con B. Conserve el resultado limitado que sí es correcto.

Resuelva la tarea ocultando las respuestas. Conserve las respuestas originales, los cálculos intermedios, las ubicaciones en las fuentes, las dudas y toda ayuda recibida, incluso una pista, un término traducido o una sugerencia de un agente. Después compárelas con las respuestas preparadas y registre las correcciones sin sustituir el intento original. Redacte una nota breve con la afirmación, sus supuestos, el cálculo, el control negativo y la próxima observación que podría refutarla. Un resultado correcto sin unidades ni identidad de la fuente no basta para demostrar transferencia. El expediente contiene cinco criterios preparados para el estudiante; sus decisiones permanecen null hasta disponer de un intento real y una revisión autorizada. Superar estos cálculos solo acreditaría competencia en este caso declarado. No acreditaría un adaptador implementado, un proceso material satisfactorio, un renderizador más rápido ni mejoras de aprendizaje en el proyecto. Compare la nota asistida con la referencia manual: si la ayuda oculta un supuesto o elimina un rechazo, corrija la nota antes de proponer cambios de método.

## Fuentes y diario de validación

- [Registro del proyecto](../../../../code/streeling/evidence/representation-release-2026-10-22/phi002-schema-replay.json)
- [Fuente primaria](https://github.com/GuitarAlchemist/Demerzel/blob/9ba9a29f6424ac8c1a6654c9b979b282a8cf216f/schemas/advisory-decision.schema.json)
- [Expediente de evidencias fijas](../../../../code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
