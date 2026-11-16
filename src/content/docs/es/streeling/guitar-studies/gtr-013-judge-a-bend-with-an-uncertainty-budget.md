---
title: Evaluar un bend con un presupuesto de incertidumbre
description: Evaluar un bend con un presupuesto de incertidumbre — Estudios de guitarra
sidebar:
  label: GTR-013 · Evaluar un bend con un presupuesto de incertidumbre
  order: 13
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-studies/es/gtr-013-judge-a-bend-with-an-uncertainty-budget.es.md
---

:::note[Streeling University]
**GTR-013** · Evaluar un bend con un presupuesto de incertidumbre · intermedio · 55 minutos

Generado por el departamento *Estudios de guitarra* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-studies/es/gtr-013-judge-a-bend-with-an-uncertainty-budget.es.md) · [Mi diario](../../journal/)

Requisitos previos: [WML-004](../../world-music-languages/wml-004-preserve-intonation-beyond-pitch-classes/)
:::

> Ejemplo construido y lectura de fuentes. No se afirma nueva interpretación, ejecución de audio o analizador, respuesta de participante ni adopción en producción. Las decisiones técnicas humanas, lingüísticas y del aprendiz siguen pendientes.

Una lectura de afinador cercana al objetivo no demuestra que un bend cumpla el criterio de práctica. La estimación puede ser incierta y la meta necesita referencia. GA puede ayudar al guitarrista a declarar esas magnitudes antes de dar feedback. Usamos una estimación construida en cents con intervalo acotado. La lección añade una regla de decisión a la representación previa, dejando sin observar detección real e interpretación.

## Leer la evidencia conservada

Leer referencia, desplazamientos construidos y límites de código del paquete de entonación conservado. Son cálculos, no una grabación de bend. NIST define el cent mediante una razón de frecuencias. Solo usamos esa razón, sin importar un umbral auditivo. La tolerancia siguiente es una elección didáctica local, no un estándar universal de buena interpretación.

[Requisito previo](../../world-music-languages/wml-004-preserve-intonation-beyond-pitch-classes/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/intonation-listening-2026-10-22/intonation.json)

[Paquete construido fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)

[Lectura primaria](https://www.nist.gov/pml/time-and-frequency-division/popular-links/time-frequency-z)

### Ejercicio 1

Usar frecuencia base `110 Hz` y subida objetivo de `2` semitonos. El intervalo es `200` cents y la frecuencia `110*2^(2/12) Hz`. La referencia fija permite reproducirlo. Nombrar la nota sin referencia ocultaría si se compara temperamento igual, otra afinación o una meta expresiva.

Expresar el objetivo en cents y como frecuencia.

<details><summary>Respuesta 1</summary>

El objetivo es `200` cents sobre la base, o `110*2^(2/12) Hz`. Es el objetivo temperado declarado, no un bend medido.

</details>

### Ejercicio 2

El estimador construido informa `195` cents con incertidumbre acotada de `3` cents. El error firmado es `195-200=-5` cents. Su signo indica una estimación baja respecto al objetivo. La incertidumbre no es un cambio adicional de altura, sino el intervalo de valores que el modelo considera compatibles con la estimación.

¿Cuál es el error puntual firmado?

<details><summary>Respuesta 2</summary>

Es `-5` cents. El signo negativo indica una estimación menor que la meta; por sí solo no establece fallo ni identifica exactamente el error verdadero.

</details>

### Ejercicio 3

Fijar tolerancia inclusiva de `10` cents. La regla conservadora exige que todo el intervalo quede dentro usando `worst_abs_error=abs(error)+uncertainty`. El máximo es `8` cents, por lo que la afirmación modelada queda establecida. No se asigna probabilidad: la incertidumbre es una cota, no una distribución.

¿Establece el caso principal el criterio elegido?

<details><summary>Respuesta 3</summary>

Sí: `8` cents no supera `10` cents. Se acepta el caso construido bajo la regla, sin certificar una toma real de un aprendiz.

</details>

### Ejercicio 4

El control negativo cambia solo la estimación a `191` cents. El error puntual es `-9` cents, todavía dentro de tolerancia, pero el máximo pasa a `12` cents. Un indicador puntual lo aceptaría, mientras la regla de intervalo no lo establece. Separar rechazar una certeza de demostrar un fallo efectivo.

¿Qué decisión corresponde al control?

<details><summary>Respuesta 4</summary>

El criterio no queda establecido: el máximo es `12` cents, superior a `10`. No demuestra que el bend verdadero estuviera fuera; la incertidumbre deja abierta esa cuestión.

</details>

### Ejercicio 5

Una tarea real debe definir cuándo se evalúa: ataque, meseta o final pueden dar respuestas distintas. También necesita evidencia de incertidumbre del estimador para esa señal y ventana. El agente debe conservar objetivo, soporte temporal, estimación, incertidumbre y regla, sin usar una nota redondeada como prueba.

¿Qué refutaría que el feedback tiene en cuenta la incertidumbre?

<details><summary>Respuesta 5</summary>

Aceptar el control solo porque su error puntual está dentro contradice la regla. La fidelidad del detector y la expresividad requieren observaciones distintas.

</details>

## Tarea con consulta de fuentes

Preparar una ficha de bend con referencia, objetivo, ventana pendiente y ambos casos construidos. Calcular manualmente errores firmados y máximos. Inspeccionar la representación en cents e identificar lo que deben aportar una grabación y un detector reales. Declarar un ejemplo de aceptación refutante antes de proponer feedback automatizado y dejar pendientes las decisiones de interpretación real.

Guardar primero la respuesta antes de revelar las correcciones preparadas. Usar la tabla o cálculo manual como base para calculadora, consulta de fuentes o ayuda de agente y registrar esa ayuda. Conservar por separado respuesta original y corregida. Relacionar cada ejercicio con un criterio preparado del paquete; todavía no hay decisiones del aprendiz. Registrar un pasaje leído y su revisión y separar lo que demuestra del siguiente paso propuesto. Informar entradas ausentes como no resueltas. Una respuesta matemática correcta respalda este ejemplo; revisión humana, ejecución real y aceptación del aprendiz necesitan sus propias observaciones conservadas.
