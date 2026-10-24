---
title: Reparar una frase sin ocultar el cambio
description: Reparar una frase sin ocultar el cambio — Guitar Alchemist Academy
sidebar:
  label: GAA-005 · Reparar una frase sin ocultar el cambio
  order: 5
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-alchemist-academy/es/gaa-005-repair-a-phrase-without-hiding-the-change.es.md
---

:::note[Streeling University]
**GAA-005** · Reparar una frase sin ocultar el cambio · early-intermediate · 35 minutos

Generado por el departamento *Guitar Alchemist Academy* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-alchemist-academy/es/gaa-005-repair-a-phrase-without-hiding-the-change.es.md) · [Mi diario](../../journal/)

Requisitos previos: [GAA-004](../../guitar-alchemist-academy/gaa-004-choose-a-useful-voicing/)
:::

> **Alcance del borrador.** Respuestas reales de las herramientas de afinación, nueva ejecución autónoma de funciones de posiciones por altura y alternativas de frase creadas para el ejemplo. Siguen pendientes las revisiones técnicas humanas, musicales, lingüísticas y con estudiantes, así como la verificación del HTML desplegado del curso. No se observó ningún solucionador temporal de GA, frase tocada ni preferencia de oyentes.

## La pregunta del proyecto

Pides a un agente que realice una frase. Encuentra un conflicto, cambia el inicio de una nota y anuncia que lo ha resuelto. La nueva frase puede ser útil, pero ha cambiado tu petición. Esta lección compara alternativas conservando las diferencias musicales entre las que debe elegir un guitarrista.

Las [consultas reales de afinación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/phrase-performance-2026-10-22/ga-tuning-probes.json) devolvieron Standard y Drop D como nombres disponibles, y las notas de Standard `E2,A2,D3,G3,B3,E4`. Estas observaciones no acreditan una revisión desplegada del código fuente ni un solucionador temporal. Las [funciones MIDI de GA fijadas a la revisión](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Types/MidiTypes.fs) proporcionan los candidatos de altura ejecutados por separado. [GTR-005](../../guitar-studies/gtr-005-plan-which-string-keeps-ringing/) explica su conversión a números de cuerda convencionales, con la cuerda 1 aguda y la cuerda 6 grave.

## 1. Conservar una copia de la frase pedida

Usa la afinación Standard y el traste máximo 5. Exige un sostenimiento independiente en una cuerda por evento activo, manteniendo cada evento sostenido su cuerda. La petición creada para el ejemplo es C4 del pulso 0 al 4, E4 del 0 al 2, G4 del 1 al 2 y D4 del 1.5 al 3. C4 significa MIDI 60; las otras alturas son 64, 67 y 62.

Entre 1.5 y 2, los cuatro eventos juntos solo tienen tres cuerdas admisibles. Este modelo no tiene una asignación válida. «No hay asignación bajo estas restricciones» es una respuesta útil: ofrece al músico una elección explícita sobre lo que puede cambiar. No juzga su capacidad.

### Ejercicio 1: preservar la pregunta original

Enumera el inicio y el final originales de D4, el límite de traste y el intervalo de conflicto. ¿Por qué deben permanecer estos valores en la comparación después de que el agente proponga una reparación?

> **Respuesta:** D4 empieza en 1.5 y termina en 3; el límite es 5. El conflicto ocurre desde 1.5 inclusive hasta 2 exclusive. Conservar estos valores distingue una solución de las restricciones originales de una frase o un rango modificados. De otro modo, una alternativa que funciona puede ocultar qué requisito se relajó.

## 2. Comparar dos cambios temporales diferentes

Primero, retrasa el inicio de D hasta el pulso 2 manteniendo su final en 3. Entonces existe una asignación con límite 5. El ataque posterior también acorta la duración de D de 1.5 pulsos a 1 pulso; no desplaza simplemente la nota entera.

Segundo, conserva el inicio original de D, pero termina E en el pulso 1.5 en vez de 2. Existe una asignación porque E libera su cuerda antes de que empiece D. Esto acorta E en lugar de cambiar el ataque de D. Los intervalos semiabiertos permiten la reutilización modelada justo en ese límite; no se midieron la liberación real ni la limpieza al tocar.

### Ejercicio 2: cuantificar las modificaciones musicales

A una frecuencia constante declarada de 120 negras por minuto, ¿cuántos milisegundos se mueve cada límite? ¿Qué nota cambia de duración en cada alternativa?

> **Respuesta:** Medio pulso de negra son 250 ms. La primera alternativa retrasa el inicio de D en 250 ms y, con su final fijo, acorta D en la misma cantidad. La segunda libera E 250 ms antes y acorta E. Son modificaciones musicales distintas, aunque ambas tengan una asignación válida en el modelo.

## 3. Preservar los tiempos de las notas cambiando el rango permitido

La tercera alternativa conserva todas las alturas, inicios y finales pedidos, pero permite trastes hasta el 10. La enumeración exhaustiva da tres planes. Sus amplitudes entre trastes positivos son 3, 7 y 7. El candidato de amplitud 3 usa C4 en la cuerda 4 traste 10, E4 en la cuerda 1 traste 0, G4 en la cuerda 2 traste 8 y D4 en la cuerda 3 traste 7.

Sin contar la cuerda al aire, la amplitud es `10-7=3`. Es un indicador declarado basado en números de traste. No es una medida en milímetros, un modelo completo de la mano ni una valoración universal de facilidad. La alternativa conserva estos campos de tiempo y altura, pero cambia la realización en las cuerdas y posiblemente el timbre; un músico debe evaluarla. [GTR-003](../../guitar-studies/gtr-003-audit-voicing-playability/) explica por qué estos indicadores requieren interpretación.

### Ejercicio 3: elegir una afirmación acotada

¿Qué conserva el candidato de amplitud 3 y qué restricción relaja? ¿Por qué «la menor amplitud entre estos tres» es una afirmación más limitada que «el mejor para el músico»?

> **Respuesta:** Conserva las cuatro alturas pedidas y todos sus valores de inicio y final, mientras amplía el traste máximo de 5 a 10. Su amplitud es la menor entre los tres planes enumerados según ese indicador. La comodidad, la técnica, el sonido y las preferencias del músico son preguntas adicionales no medidas, por lo que el indicador no elige de forma universal.

## 4. Rechazar reparaciones que resuelven otra petición en silencio

Omitir D deja un plan válido, pero elimina un evento pedido. Reafinar la cuerda grave a Drop D manteniendo el límite 5 deja cero planes válidos para la petición original de notas agudas: sus candidatos pertinentes no cambian. Una opción disponible en una herramienta no es automáticamente pertinente para el conflicto detectado.

| Alternativa | Planes válidos en el modelo | Cambio principal |
| --- | --- | --- |
| Retrasar el ataque de D y conservar su final | 1 | Inicio y duración de D |
| Liberar E antes | 1 | Final y duración de E |
| Permitir trastes hasta el 10 | 3 | Rango permitido y realización en las cuerdas |
| Omitir D | 1 | Conjunto de eventos pedidos |
| Afinación Drop D, límite 5 | 0 | Afinación de la cuerda grave; el conflicto permanece |

Estos recuentos corresponden a un modelo de asignación creado para el ejemplo. No son salidas del servicio, puntuaciones de oyentes ni pruebas de que un cambio esté autorizado.

### Ejercicio 4: diagnosticar el atajo propuesto

Un agente elige Drop D porque la herramienta lo ofrece y luego elimina D4 cuando el conflicto persiste. ¿Puede anunciar que ha resuelto la petición original? Explica ambas decisiones.

> **Respuesta:** No. El cambio de afinación no añade ninguna cuerda admisible para estas alturas agudas con límite 5 y deja el conflicto. Eliminar D4 cambia el conjunto de eventos requeridos, aunque la frase restante de tres eventos tenga un plan válido. Presenta esa alternativa y su omisión de forma explícita en vez de llamarla una realización preservada.

## 5. Presentar opciones que un músico pueda valorar

El [registro fijo de alternativas](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/phrase-performance-2026-10-22/repair-options.json) separa la viabilidad de los campos conservados. Una respuesta útil del agente puede conservar la petición original, explicar el intervalo en conflicto, presentar unas pocas alternativas explícitas y señalar las observaciones de ejecución que faltan. La objeción más fuerte a la reparación automática es que un modelo geométrico pequeño puede eliminar, al optimizar, una articulación, un timbre o una intención que el músico valora. La alternativa más sencilla es conservar la petición sin resolver y preguntar qué cambio es aceptable antes de aplicarlo.

### Ejercicio 5: redactar la propuesta del agente

Ofrece dos alternativas a un guitarrista que no ha autorizado cambios temporales. Incluye lo que conserva y cambia cada una, y una observación aún necesaria antes de afirmar que se ha tocado con éxito o de publicar el resultado.

> **Respuesta:** Ofrece el candidato de rango ampliado como opción que conserva las alturas y los tiempos declarados, pero cambia el rango y la realización en las cuerdas; su digitación y su sonido requieren la comprobación de un músico. Ofrece un ataque retrasado de D o una liberación anticipada de E solo como propuesta explícita de modificación musical, indicando el límite y la duración modificados. Ninguna debe aplicarse en silencio ni describirse como una interpretación tocada con éxito. La elección aceptada por el músico y su ensayo real siguen sin registrarse.
