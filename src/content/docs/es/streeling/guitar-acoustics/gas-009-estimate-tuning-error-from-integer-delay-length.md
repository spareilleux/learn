---
title: Estimar el error de afinación de una longitud de retardo entera
description: Estimar el error de afinación de una longitud de retardo entera — Acústica de la guitarra y síntesis sonora
sidebar:
  label: GAS-009 · Estimar el error de afinación de una longitud de retardo entera
  order: 9
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-acoustics/es/gas-009-estimate-tuning-error-from-integer-delay-length.es.md
---

:::note[Streeling University]
**GAS-009** · Estimar el error de afinación de una longitud de retardo entera · intermedio · 45 minutos

Generado por el departamento *Acústica de la guitarra y síntesis sonora* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-acoustics/es/gas-009-estimate-tuning-error-from-integer-delay-length.es.md) · [Mi diario](../../journal/)

Requisitos previos: [GAS-005](../../guitar-acoustics/gas-005-separate-a-partial-peak-from-a-period/)
:::

> **Borrador y límites de la evidencia.** Este curso presenta un modelo construido y lecturas de fuentes. Las decisiones técnicas humanas, musicales, lingüísticas y de alumnos siguen pendientes. No se afirma ningún nuevo renderizado, ejecución de analizador, interpretación, escucha ni observación de alumnos. Los fallos históricos mantienen su estado.

## La pregunta del proyecto

Una frecuencia solicitada no siempre cabe en un retardo entero. GAS005 presentaba una razón; aquí se comparan redondeos con una tolerancia declarada. Reloj y objetivos son constantes construidas. El motor GA también incluye retardo fraccionario y filtros: este modelo simplificado no predice su altura renderizada.

## Leer la evidencia del proyecto

Lea el prerrequisito y el artefacto conservado antes de aplicar el modelo. Localice la representación, transformación o exclusión pertinente. El paquete fijo conserva identidad de fuentes, alcance de lectura y valores construidos; una fuente documenta su contenido en esa revisión, sin demostrar despliegue actual. Separe observación derivada del texto y propuesta inferida. Cuando haya referencia primaria, respete su alcance declarado sin extenderlo a casos no admitidos.

[Prerrequisito: gas-005-separate-a-partial-peak-from-a-period](../../guitar-acoustics/gas-005-separate-a-partial-peak-from-a-period/)

[Artefacto del proyecto conservado](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/vendor/lib.rs)

[Paquete de datos construidos](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-a.json)

[Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)

## 1. Ejercicio 1

A 44100 Hz y objetivo 1000 Hz, el retardo ideal es 44.1 muestras. Tanto truncar como redondear al entero más cercano elige 44. La longitud cuenta muestras; se convierte en tiempo dividiendo por el reloj.

¿Qué frecuencia produce longitud 44?

> **Respuesta.** `44100/44` da aproximadamente 1002.272727273 Hz, por encima del objetivo.

## 2. Ejercicio 2

Use cents con signo `1200*log2(f/target)`. La longitud 44 da aproximadamente 3.930158439 cents; la 45 da aproximadamente -34.975614791 cents. El signo indica dirección. Una tolerancia simétrica compara el valor absoluto: hay que evaluar la razón resultante, no solo la distancia en muestras.

¿Qué longitud cumple la tolerancia estipulada de 5 cents?

> **Respuesta.** La longitud 44 cumple; la 45 falla. Es un criterio construido, no un umbral auditivo medido.

## 3. Ejercicio 3

El intervalo entre longitudes vecinas depende de su posición: `1200*log2((N+1)/N)` da su magnitud positiva. En retardos cortos una muestra puede desplazar más la razón. Una política suficiente para un objetivo no certifica todo un rango.

¿El caso correcto a 1000 Hz certifica todos los objetivos?

> **Respuesta.** No. Deben comprobarse el intervalo local y la posición de cada objetivo entre enteros.

## 4. Ejercicio 4

Como control negativo, cambie el objetivo a 1100 Hz conservando el reloj. La longitud cercana es 40 y produce 1102.5 Hz. Debe calcularse el error en vez de concluir por la etiqueta de redondeo. Sigue siendo aproximadamente 3.930158439 cents, así que este control cumple.

¿Qué contraejemplo más fuerte debe sustituir ese control ineficaz?

> **Respuesta.** Use 1090 Hz: la longitud cercana 40 da 1102.5 Hz y supera 5 cents.

## 5. Ejercicio 5

El código conservado distingue longitud entera y estado fraccionario. Mantenga esa diferencia en toda recomendación. Un fallo del modelo sencillo motiva revisar fase e interpolación; no identifica un defecto del bucle completo. El antiguo fallo del criterio de decaimiento sigue separado.

¿Qué resultado puede afirmarse?

> **Respuesta.** Solo los resultados calculados del modelo entero, con reloj, objetivo y política. La afinación real y el juicio musical no se observaron.

## Tarea con consulta de fuentes

Prepare una breve nota de revisión a partir del caso fijo antes de abrir las soluciones. Reproduzca primero manualmente el cálculo o la tabla, conservando unidades, soporte y supuestos. Ese resultado directo es la referencia de cualquier respuesta asistida por fuentes o agentes. Examine después el artefacto enlazado e identifique un límite preciso relevante. Registre el fragmento o campo realmente utilizado, su revisión, su respuesta y toda ayuda recibida. Se permiten calculadora y consulta; indíquelas en lugar de presentar el resultado como recuerdo sin ayuda.

Aplique el control negativo además del caso principal. Escriba qué resultado observable refutaría su conclusión e indique si el control lo aporta realmente. Si falta una entrada, mantenga el resultado sin resolver en vez de elegir un valor plausible. Compare toda abstracción propuesta con la referencia manual antes de recomendar otro flujo de agentes o DSL. La clave prepara una comprobación; no registra su intento. Conserve la respuesta anterior a la revelación, cualquier corrección posterior y su motivo.

El paquete contiene cinco criterios de alumnos preparados que corresponden a los ejercicios. Sus decisiones siguen nulas hasta conservar respuestas reales, ayuda y revisión. Una aritmética correcta solo respalda el modelo declarado. Una decisión útil para el proyecto requiere todavía el juicio humano o la observación de ejecución en su ámbito correspondiente. Registre comprobaciones reales, errores y refinamientos en el diario enlazado; distinga pruebas ejecutadas de pruebas previstas.
