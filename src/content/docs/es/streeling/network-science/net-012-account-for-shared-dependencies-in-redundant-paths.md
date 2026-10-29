---
title: Contabilizar dependencias compartidas en rutas redundantes
description: Contabilizar dependencias compartidas en rutas redundantes — Ciencia de redes
sidebar:
  label: NET-012 · Contabilizar dependencias compartidas en rutas redundantes
  order: 12
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/network-science/es/net-012-account-for-shared-dependencies-in-redundant-paths.es.md
---

:::note[Streeling University]
**NET-012** · Contabilizar dependencias compartidas en rutas redundantes · intermedio · 45 minutos

Generado por el departamento *Ciencia de redes* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/network-science/es/net-012-account-for-shared-dependencies-in-redundant-paths.es.md) · [Mi diario](../../journal/)

Requisitos previos: [NET-003](../../network-science/net-003-worker-lane-coverage-and-fragility/)
:::

> Esta lección utiliza un caso construido y fuentes consultadas. Los recuentos, tiempos, etiquetas y señales son entradas didácticas inventadas. La revisión técnica humana, la revisión lingüística, los intentos reales, la ejecución, la adopción en producción y la publicación siguen pendientes de decisión.

Un coordinador ve dos rutas para obtener una revisión y afirma que cualquiera rescata a la otra. Ambas pueden depender del mismo servicio de repositorio o credenciales. El prerrequisito cuenta opciones declaradas tras una interrupción. Esta lección plantea una pregunta probabilística cuando las rutas comparten un requisito. Dos caminos en un grafo no proporcionan por sí solos dos oportunidades independientes.

Condicione primero a que la dependencia compartida esté disponible. En esa condición se estipula independencia de las ramas, por lo que su fallo conjunto es el producto de probabilidades de fallo. Réstelo de la unidad para obtener la unión condicional. Después multiplique por el éxito compartido, pues ninguna rama funciona sin él. Ese factor queda fuera de la unión; copiarlo como eventos independientes cambiaría el modelo.

El atajo tentador calcula el éxito marginal de cada ruta y después las trata como independientes. Comparten una causa de fallo, así que el atajo sobrestima el éxito. El control debilita ese requisito manteniendo el comportamiento condicional de las ramas. La diferencia ilustra el coste oculto. Son probabilidades inventadas, sin estimar fiabilidad real de proveedores ni exposición del usuario.

La utilidad [F#](https://learn.microsoft.com/dotnet/fsharp/) conservada compone resultados paralelos y fallos. Aporta un límite para examinar, sin mediciones ni teorema de independencia. La procedencia [W3C](https://www.w3.org/TR/2013/REC-prov-dm-20130430/) distingue actividades y entidades usadas, lo que ayuda a dibujar el requisito común. Antes de proponer redundancia, dibuje el árbol de condiciones y busque requisitos compartidos. Recuento de rutas, declaración de paralelismo y fiabilidad observada son evidencias distintas.

## Fuentes y alcance del proyecto

Lea el prerrequisito antes de usar el modelo. Examine el artefacto conservado del proyecto en la revisión registrada en el expediente e identifique el campo o la rama que respalda la observación. La fuente aporta una representación o un comportamiento declarado; no convierte el caso inventado en un resultado observado del proyecto. La lectura primaria aporta el concepto indicado dentro de su alcance declarado.

[Prerrequisito: net-003-worker-lane-coverage-and-fragility](../../network-science/net-003-worker-lane-coverage-and-fragility/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/functional-composition/vendor/GaAsync.fs)

[Lectura primaria: W3C Recommendation 2013-04-30](https://www.w3.org/TR/2013/REC-prov-dm-20130430/)

[Lectura primaria: Microsoft F# documentation, read 2026-10-24](https://learn.microsoft.com/dotnet/fsharp/)

## Modelo fijado y control

```json
{
  "values": {
    "shared_success": 0.95,
    "branch_a_success_given_shared": 0.8,
    "branch_b_success_given_shared": 0.9
  },
  "formula": "success=shared_success*(1-(1-a)*(1-b)); marginal_a=shared_success*a; marginal_b=shared_success*b; naive_independent=1-(1-marginal_a)*(1-marginal_b).",
  "expected": {
    "conditional_branch_union": 0.98,
    "success": 0.931,
    "marginal_a": 0.76,
    "marginal_b": 0.855,
    "naive_independent": 0.9652
  },
  "negative_control": {
    "values": {
      "shared_success": 0.5,
      "branch_a_success_given_shared": 0.8,
      "branch_b_success_given_shared": 0.9
    },
    "expected": {
      "conditional_branch_union": 0.98,
      "success": 0.49,
      "marginal_a": 0.4,
      "marginal_b": 0.45,
      "naive_independent": 0.67
    },
    "why": "A weaker shared dependency worsens both paths together; independent marginal multiplication overstates the union."
  },
  "assumptions": [
    "Branch successes independent conditional on the shared dependency succeeding.",
    "Both paths fail if the shared dependency fails.",
    "Authored probabilities refer to the same window and operation."
  ],
  "limits": "No live provider availability measured; correlation outside this conditional model may differ."
}
```

### Ejercicio 1

Calcule la probabilidad condicional de éxito de alguna rama.

<details><summary>Respuesta 1</summary>

Es `1-(1-0.8)*(1-0.9)=0.98`. La independencia se aplica solo tras condicionar al éxito compartido. Sin esa condición, las rutas comparten una causa de fallo.

</details>

### Ejercicio 2

Calcule el éxito total del modelo principal.

<details><summary>Respuesta 2</summary>

Es `0.95*0.98=0.931`. Deben funcionar el requisito compartido y la unión de ramas. El resultado no puede superar el éxito compartido bajo estos supuestos.

</details>

### Ejercicio 3

Calcule el atajo engañoso de marginales independientes.

<details><summary>Respuesta 3</summary>

Las marginales son `0.76` y `0.855`; el atajo da `0.9652`. Sobrestima `0.931` al ignorar fallos comunes. Marginales correctas no implican independencia conjunta.

</details>

### Ejercicio 4

Aplique el control de dependencia compartida más débil.

<details><summary>Respuesta 4</summary>

La unión condicional sigue en `0.98`, el éxito del modelo pasa a `0.49` y el atajo a `0.67`. Mejorar solo ramas independientes no elimina el límite común.

</details>

### Ejercicio 5

¿Qué justificaría una afirmación real de rutas redundantes?

<details><summary>Respuesta 5</summary>

Conserve operación, ventana, resultados medidos compartidos y de ramas, servicios comunes y supuestos justificados. La utilidad y probabilidades inventadas enseñan a preguntar, sin establecer disponibilidad real ni autorizar un mecanismo nuevo de respaldo.

</details>

## Tarea con consulta de fuentes

Empiece con una tabla en papel antes de abrir las respuestas. Copie las entradas y sus unidades, aplique la operación declarada y conserve los resultados intermedios. Este cálculo directo es la referencia manual para comparar una respuesta asistida o una notación componible propuesta. Una respuesta más corta no ofrece una ventaja demostrada si pierde la identidad de una entrada, una categoría de fallo o el contraejemplo.

Después examine el pasaje concreto registrado en el expediente. Cite únicamente el pequeño campo o la rama necesarios para su explicación y registre su revisión. Tras guardar su primera respuesta, pida a un asistente que cuestione un supuesto. Conserve la instrucción, la respuesta, las correcciones aceptadas y las sugerencias rechazadas. Se permiten la consulta de fuentes y la calculadora; registre esa ayuda para no presentar el resultado como recuerdo sin asistencia.

Aplique la entrada modificada del control negativo y formule un resultado observable que refutaría su conclusión antes de recomendar cambios. Un control inesperado exige revisar el cálculo y los supuestos antes de modificar el trabajo del proyecto. Entregue conjuntamente la respuesta inicial, la corregida, el historial de ayuda y la incertidumbre restante. El expediente prepara cinco criterios, uno por ejercicio, cuyas decisiones quedan pendientes. Las soluciones y comprobaciones del autor no rellenan esas decisiones. Una futura comparación mediante dogfooding necesita intentos reales sobre la misma tarea y una referencia manual conservada; esta lección no exige implementar ningún agente o DSL nuevo.

[Expediente fijado de la unidad](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)
