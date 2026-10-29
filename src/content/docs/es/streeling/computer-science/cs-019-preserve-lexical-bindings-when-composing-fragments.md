---
title: Preservar los enlaces léxicos al componer fragmentos
description: Preservar los enlaces léxicos al componer fragmentos — Ciencias de la computación
sidebar:
  label: CS-019 · Preservar los enlaces léxicos al componer fragmentos
  order: 19
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/computer-science/es/cs-019-preserve-lexical-bindings-when-composing-fragments.es.md
---

:::note[Streeling University]
**CS-019** · Preservar los enlaces léxicos al componer fragmentos · intermedio · 45 minutos

Generado por el departamento *Ciencias de la computación* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/computer-science/es/cs-019-preserve-lexical-bindings-when-composing-fragments.es.md) · [Mi diario](../../journal/)

Requisitos previos: [CS-006](../../computer-science/cs-006-ixql-pipeline-composition/)
:::

> Esta lección utiliza un caso construido y fuentes consultadas. Los recuentos, tiempos, etiquetas y señales son entradas didácticas inventadas. La revisión técnica humana, la revisión lingüística, los intentos reales, la ejecución, la adopción en producción y la publicación siguen pendientes de decisión.

Un compañero propone componer fragmentos de un pipeline de agentes concatenando su texto. Ambos usan el mismo nombre temporal. El resultado parece legible, pero una referencia libre puede pasar a designar el nuevo enlace local. El prerrequisito sigue dependencias entre etapas; esta lección sigue la identidad de los enlaces dentro de una etapa. El problema puede surgir antes de ejecutar herramientas, de modo que un ejemplo aritmético correcto no demuestra una composición segura.

El fragmento explicativo suma un argumento incrementado y un valor procedente del entorno. El mismo nombre impreso existe localmente y en ese entorno. La referencia libre prevista debe conservar su enlace original. Una sustitución textual ingenua hace que lea el valor local y produce otra respuesta. Renombrar el enlace local y todas sus referencias ligadas conserva el significado; cambiar todas las apariciones de la misma palabra también puede alterar referencias libres.

El ejemplo de alcance léxico de la guía de [Racket](https://docs.racket-lang.org/guide/pattern-macros.html) muestra por qué los identificadores introducidos requieren disciplina de enlace. Usamos ese concepto sin afirmar que IXQL sea un lenguaje de macros de Racket. La utilidad [F#](https://learn.microsoft.com/dotnet/fsharp/) conservada recibe funciones con parámetros léxicos y pasa valores exitosos a callbacks. No implementa un expansor textual de fragmentos. Examinar sus parámetros permite entender por qué componer funciones y concatenar texto tienen obligaciones diferentes.

El control iguala intencionadamente el valor externo y el local. Ambos cálculos coinciden pese a sus estructuras de enlace distintas. Este éxito engañoso oculta la captura. Una propuesta de DSL debería conservar variables libres e identidades de enlace y después probar valores desiguales. Basta dibujar en papel las relaciones entre apariciones y definiciones para contestar; no hace falta crear un parser.

## Fuentes y alcance del proyecto

Lea el prerrequisito antes de usar el modelo. Examine el artefacto conservado del proyecto en la revisión registrada en el expediente e identifique el campo o la rama que respalda la observación. La fuente aporta una representación o un comportamiento declarado; no convierte el caso inventado en un resultado observado del proyecto. La lectura primaria aporta el concepto indicado dentro de su alcance declarado.

[Prerrequisito: cs-006-ixql-pipeline-composition](../../computer-science/cs-006-ixql-pipeline-composition/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/functional-composition/vendor/GaAsync.fs)

[Lectura primaria: Racket Guide, section 16.1.2, read 2026-10-24](https://docs.racket-lang.org/guide/pattern-macros.html)

[Lectura primaria: Microsoft F# documentation, read 2026-10-24](https://learn.microsoft.com/dotnet/fsharp/)

## Modelo fijado y control

```json
{
  "values": {
    "outer_x": 10,
    "argument": 3,
    "local_name": "x",
    "local_increment": 1
  },
  "formula": "local=argument+local_increment; lexical_result=local+outer_x; captured_result=local+local; renamed_result=local+outer_x, renaming only the bound local identifier.",
  "expected": {
    "lexical_result": 14,
    "captured_result": 8,
    "renamed_result": 14
  },
  "negative_control": {
    "values": {
      "outer_x": 4,
      "argument": 3,
      "local_name": "x",
      "local_increment": 1
    },
    "expected": {
      "lexical_result": 8,
      "captured_result": 8,
      "renamed_result": 8
    },
    "why": "Coincidental equal values hide capture; one agreeing execution is not proof of hygiene."
  },
  "assumptions": [
    "One local binding and one intended free outer reference.",
    "Exact integers and pure expressions; this is explanatory notation, not IXQL syntax."
  ],
  "limits": "No parser, macro expander or GA DSL change is supplied; capture must be reasoned about by binding identity."
}
```

### Ejercicio 1

Calcule el valor local y el resultado léxico previsto del caso principal.

<details><summary>Respuesta 1</summary>

El valor local es `4`; el resultado previsto es `14`. La contribución externa sigue siendo `10` porque la referencia libre conserva su enlace del entorno. El argumento no es el propio valor externo.

</details>

### Ejercicio 2

¿Qué resultado produce la interpretación con captura y por qué?

<details><summary>Respuesta 2</summary>

Produce `8`, al sumar dos veces el valor local `4`. La aritmética es coherente, pero la referencia designa el enlace equivocado. La diferencia numérica revela un error semántico y no un fallo de cálculo.

</details>

### Ejercicio 3

¿Qué debe cambiar un renombrado alfa válido?

<details><summary>Respuesta 3</summary>

Cambia el nombre local ligado y solo las apariciones ligadas por esa definición. Conserva la referencia externa libre y produce `14`. Un reemplazo global de la palabra no demuestra esa relación.

</details>

### Ejercicio 4

Aplique el control. ¿Por qué la coincidencia no demuestra composición segura?

<details><summary>Respuesta 4</summary>

Ambas interpretaciones producen `8` cuando el valor externo es `4`. Valores iguales ocultan enlaces diferentes. Es una trampa de coincidencia: se necesita análisis estructural del alcance además del contraejemplo principal.

</details>

### Ejercicio 5

¿Qué debe conservar un asistente al proponer un fragmento reutilizable?

<details><summary>Respuesta 5</summary>

Debe conservar entradas, identificadores libres, identidades de enlaces locales y contexto previsto. Rechace la propuesta si renombrar cambia una referencia libre o si presenta esta tabla como prueba de un DSL higiénico implementado.

</details>

## Tarea con consulta de fuentes

Empiece con una tabla en papel antes de abrir las respuestas. Copie las entradas y sus unidades, aplique la operación declarada y conserve los resultados intermedios. Este cálculo directo es la referencia manual para comparar una respuesta asistida o una notación componible propuesta. Una respuesta más corta no ofrece una ventaja demostrada si pierde la identidad de una entrada, una categoría de fallo o el contraejemplo.

Después examine el pasaje concreto registrado en el expediente. Cite únicamente el pequeño campo o la rama necesarios para su explicación y registre su revisión. Tras guardar su primera respuesta, pida a un asistente que cuestione un supuesto. Conserve la instrucción, la respuesta, las correcciones aceptadas y las sugerencias rechazadas. Se permiten la consulta de fuentes y la calculadora; registre esa ayuda para no presentar el resultado como recuerdo sin asistencia.

Aplique la entrada modificada del control negativo y formule un resultado observable que refutaría su conclusión antes de recomendar cambios. Un control inesperado exige revisar el cálculo y los supuestos antes de modificar el trabajo del proyecto. Entregue conjuntamente la respuesta inicial, la corregida, el historial de ayuda y la incertidumbre restante. El expediente prepara cinco criterios, uno por ejercicio, cuyas decisiones quedan pendientes. Las soluciones y comprobaciones del autor no rellenan esas decisiones. Una futura comparación mediante dogfooding necesita intentos reales sobre la misma tarea y una referencia manual conservada; esta lección no exige implementar ningún agente o DSL nuevo.

[Expediente fijado de la unidad](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)
