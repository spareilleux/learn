---
title: Distinguir los parciales de una cuerda rígida de los armónicos
description: Distinguir los parciales de una cuerda rígida de los armónicos — Acústica de la guitarra y síntesis sonora
sidebar:
  label: GAS-010 · Distinguir los parciales de una cuerda rígida de los armónicos
  order: 10
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-acoustics/es/gas-010-distinguish-stiff-string-partials-from-harmonics.es.md
---

:::note[Streeling University]
**GAS-010** · Distinguir los parciales de una cuerda rígida de los armónicos · intermedio · 45 minutos

Generado por el departamento *Acústica de la guitarra y síntesis sonora* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-acoustics/es/gas-010-distinguish-stiff-string-partials-from-harmonics.es.md) · [Mi diario](../../journal/)

Requisitos previos: [GAS-005](../../guitar-acoustics/gas-005-separate-a-partial-peak-from-a-period/), [GAS-006](../../guitar-acoustics/gas-006-relate-pluck-position-to-string-modes/)
:::

> **Borrador y límites de la evidencia.** Este curso presenta un modelo construido y lecturas de fuentes. Las decisiones técnicas humanas, musicales, lingüísticas y de alumnos siguen pendientes. No se afirma ningún nuevo renderizado, ejecución de analizador, interpretación, escucha ni observación de alumnos. Los fallos históricos mantienen su estado.

## La pregunta del proyecto

Una etiqueta espectral de GA puede llamar armónico a cualquier parcial. Solo es exacto si su frecuencia es un múltiplo entero de una fundamental de referencia. Aquí un modelo estipulado, inspirado en la rigidez, cambia las razones de frecuencia sin tratar amplitudes. La normalización al primer parcial mantiene explícita la referencia.

## Leer la evidencia del proyecto

Lea el prerrequisito y el artefacto conservado antes de aplicar el modelo. Localice la representación, transformación o exclusión pertinente. El paquete fijo conserva identidad de fuentes, alcance de lectura y valores construidos; una fuente documenta su contenido en esa revisión, sin demostrar despliegue actual. Separe observación derivada del texto y propuesta inferida. Cuando haya referencia primaria, respete su alcance declarado sin extenderlo a casos no admitidos.

[Prerrequisito: gas-005-separate-a-partial-peak-from-a-period](../../guitar-acoustics/gas-005-separate-a-partial-peak-from-a-period/)

[Prerrequisito: gas-006-relate-pluck-position-to-string-modes](../../guitar-acoustics/gas-006-relate-pluck-position-to-string-modes/)

[Artefacto del proyecto conservado](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/vendor/lib.rs)

[Paquete de datos construidos](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-a.json)

[Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)

[Referencia primaria](https://www.dsprelated.com/freebooks/pasp/Stiff_String.html)

## 1. Ejercicio 1

Defina `f_n=n*100*sqrt((1+B*n*n)/(1+B))` con `B=.01`, sin unidades. El denominador fija exactamente el primer parcial en 100 Hz. Omitirlo cambiaría la referencia. Este coeficiente construido no es el control de dispersión de GA.

¿Qué da la fórmula para el primer parcial?

> **Respuesta.** Para n=1 la razón bajo la raíz es 1, por lo que resulta 100 Hz.

## 2. Ejercicio 2

El segundo parcial es aproximadamente 202.948561985 Hz, por encima de la referencia armónica 200 Hz. Su razón respecto al doble del primero supera la unidad. Llamarlo segundo parcial conserva su posición; llamarlo segundo armónico exacto borraría la discrepancia.

Dé la referencia armónica y el signo del residuo.

> **Respuesta.** La referencia es 200 Hz; el residuo es positivo porque el segundo parcial modelado está por encima.

## 3. Ejercicio 3

Para el tercer parcial, la fórmula da aproximadamente 311.654797607 Hz, en vez de 300 Hz. La discrepancia crece con el índice en este modelo de coeficiente positivo. No establece un efecto audible universal: faltan amplitud, banda, duración y tarea de escucha.

¿El cálculo demuestra audibilidad o preferencia?

> **Respuesta.** No. Solo calcula una discrepancia del modelo; los informes perceptivos requieren otras observaciones y una comparación definida.

## 4. Ejercicio 4

Fije B en 0 como control negativo. La fórmula devuelve `[100,200,300]`, múltiplos armónicos exactos. Comprueba normalización y sentido de comparación. Una convención incorrecta para el primer parcial podría fabricar un residuo incluso en el control de cuerda flexible.

¿Qué debe devolver el control de coeficiente nulo?

> **Respuesta.** Debe dar `[100,200,300]` Hz. Una discrepancia no nula refutaría la aplicación de la fórmula o la convención de referencia declarada.

## 5. Ejercicio 5

El código identifica estado de dispersión; el texto acústico explica propagación dependiente de la frecuencia. Ninguno calibra nuestro coeficiente respecto a un ajuste GA. Separe modelo construido y espectro ajustado, conservando identidades de parciales y picos inciertos. Sigue vigente la advertencia del prerrequisito sobre el pico más alto.

¿Qué falta antes de recomendar un ajuste GA?

> **Respuesta.** Falta una relación ejecutada y versionada entre control y frecuencias medidas, estimaciones calibradas y una tarea de aceptación declarada.

## Tarea con consulta de fuentes

Prepare una breve nota de revisión a partir del caso fijo antes de abrir las soluciones. Reproduzca primero manualmente el cálculo o la tabla, conservando unidades, soporte y supuestos. Ese resultado directo es la referencia de cualquier respuesta asistida por fuentes o agentes. Examine después el artefacto enlazado e identifique un límite preciso relevante. Registre el fragmento o campo realmente utilizado, su revisión, su respuesta y toda ayuda recibida. Se permiten calculadora y consulta; indíquelas en lugar de presentar el resultado como recuerdo sin ayuda.

Aplique el control negativo además del caso principal. Escriba qué resultado observable refutaría su conclusión e indique si el control lo aporta realmente. Si falta una entrada, mantenga el resultado sin resolver en vez de elegir un valor plausible. Compare toda abstracción propuesta con la referencia manual antes de recomendar otro flujo de agentes o DSL. La clave prepara una comprobación; no registra su intento. Conserve la respuesta anterior a la revelación, cualquier corrección posterior y su motivo.

El paquete contiene cinco criterios de alumnos preparados que corresponden a los ejercicios. Sus decisiones siguen nulas hasta conservar respuestas reales, ayuda y revisión. Una aritmética correcta solo respalda el modelo declarado. Una decisión útil para el proyecto requiere todavía el juicio humano o la observación de ejecución en su ámbito correspondiente. Registre comprobaciones reales, errores y refinamientos en el diario enlazado; distinga pruebas ejecutadas de pruebas previstas.
