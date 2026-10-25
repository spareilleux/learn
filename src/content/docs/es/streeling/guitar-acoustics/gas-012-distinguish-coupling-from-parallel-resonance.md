---
title: Distinguir acoplamiento y resonancias en paralelo
description: Distinguir acoplamiento y resonancias en paralelo — Acústica de la guitarra y síntesis sonora
sidebar:
  label: GAS-012 · Distinguir acoplamiento y resonancias en paralelo
  order: 12
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-acoustics/es/gas-012-distinguish-coupling-from-parallel-resonance.es.md
---

:::note[Streeling University]
**GAS-012** · Distinguir acoplamiento y resonancias en paralelo · intermedio · 55 minutos

Generado por el departamento *Acústica de la guitarra y síntesis sonora* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-acoustics/es/gas-012-distinguish-coupling-from-parallel-resonance.es.md) · [Mi diario](../../journal/)

Requisitos previos: [GAS-007](../../guitar-acoustics/gas-007-distinguish-body-poles-from-string-partials/)
:::

> Ejemplo construido y lectura de fuentes. No se afirma nueva interpretación, ejecución de audio o analizador, respuesta de participante ni adopción en producción. Las decisiones técnicas humanas, lingüísticas y del aprendiz siguen pendientes.

Una resonancia parecida a la caja en un renderizado no demuestra que la energía pueda volver desde la caja a una cuerda. La distinción importa cuando una futura lección o control de GA promete respuesta simpática. Construimos un análogo mecánico simétrico con acoplamiento explícito en las ecuaciones. La separación modal se calcula independientemente. El análogo explica la relación necesaria entre coordenadas; no afirma que un motor existente la implemente ni que coincida con una guitarra acústica.

## Leer la evidencia conservada

Leer las declaraciones Rust conservadas de voz y resonador de caja y la recurrencia del resonador impulsada por la entrada. Establecen variables y una expresión concreta, no acoplamiento recíproco en todas las rutas. UNSW explica los modos como formas permitidas de vibración. Usamos ese concepto para deducir nuestro modelo; no se consiguió leer ninguna página de cuerdas simpáticas.

[Requisito previo](../../guitar-acoustics/gas-007-distinguish-body-poles-from-string-partials/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/vendor/lib.rs)

[Paquete construido fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)

[Lectura primaria](https://www.phys.unsw.edu.au/jw/strings.html)

### Ejercicio 1

Cada masa vale `1 kg`, la rigidez de anclaje `100 N/m` y la rigidez de conexión `150 N/m`. Con desplazamientos `x1` y `x2`, la primera ecuación es `m*x1''=-k*x1-kc*(x1-x2)`; la segunda intercambia coordenadas. La fuerza de conexión depende de su diferencia: indicar dos frecuencias separadas no define este modelo.

¿Qué relación física hace que el modelo esté acoplado?

<details><summary>Respuesta 1</summary>

La fuerza sobre cada masa incluye el desplazamiento de la otra mediante `kc*(x1-x2)`. Aparecen ambas direcciones; una suma posterior no expresa esa relación.

</details>

### Ejercicio 2

Cuando `x1=x2`, el resorte de conexión no se estira. La frecuencia angular es `sqrt(k/m)=10 rad/s`, equivalente a `10/(2*pi) Hz`. Separar frecuencia angular y ordinaria evita un error de factor. El resultado procede de la simetría y los parámetros construidos, sin identificar un modo real de guitarra.

¿Cuál es el modo en el mismo sentido y por qué no lo eleva el acoplamiento?

<details><summary>Respuesta 2</summary>

Su frecuencia angular es `10 rad/s`, o `10/(2*pi) Hz`. El desplazamiento igual no deforma la conexión y solo interviene la rigidez del anclaje.

</details>

### Ejercicio 3

Cuando `x1=-x2`, la conexión se estira el doble de cada desplazamiento. La rigidez efectiva es `k+2*kc`, por lo que `sqrt((k+2*kc)/m)=20 rad/s`, o `20/(2*pi) Hz`. Este modo distingue el acoplamiento recíproco de dos osciladores idénticos independientes. La separación depende de la simetría; masas distintas exigen otro cálculo.

Calcular el modo opuesto e identificar la rigidez añadida.

<details><summary>Respuesta 3</summary>

Es `20 rad/s`, o `20/(2*pi) Hz`. Se añade `2*kc`, porque los desplazamientos opuestos cambian la conexión el doble de una coordenada.

</details>

### Ejercicio 4

El control negativo fija la conexión en `0 N/m` conservando masas y anclajes. Ambos modos quedan en `10 rad/s`. Cada oscilador sigue pudiendo vibrar, pero desaparece la separación. Esto refuta una explicación basada solo en la rigidez de anclaje inalterada o en observar dos coordenadas.

¿Un acoplamiento nulo implica silencio?

<details><summary>Respuesta 4</summary>

No. Ambos modos son `10 rad/s` y siguen siendo posibles oscilaciones independientes. El control elimina la separación por acoplamiento, no todo movimiento ni todas las fuentes de sonido.

</details>

### Ejercicio 5

Una revisión debe localizar la variable que un componente devuelve al otro antes de afirmar intercambio simpático. Un filtro de caja alimentado por la mezcla de cuerdas puede colorear la salida sin aportar realimentación. Tampoco un fragmento demuestra ausencia en todo el repositorio. Conservar ruta e inicio y pedir una intervención real para afirmar comportamiento de producción.

¿Qué observación cuestionaría una explicación del motor por acoplamiento?

<details><summary>Respuesta 5</summary>

Si modificar el supuesto acoplamiento no cambia la interacción de estado ni la predicción modal en una prueba controlada, el mecanismo carece de apoyo. Nuestra álgebra propone ese diagnóstico, sin ejecutarlo.

</details>

## Tarea con consulta de fuentes

Dibujar las fuerzas y deducir manualmente ambas frecuencias; repetir sin conexión. Inspeccionar las declaraciones de voz y resonador y redactar una afirmación limitada a lo visible. Proponer dónde haría falta observar intercambios bidireccionales. Mantener por separado la evidencia del análogo mecánico, la implementación y la respuesta medida de una guitarra.

Guardar primero la respuesta antes de revelar las correcciones preparadas. Usar la tabla o cálculo manual como base para calculadora, consulta de fuentes o ayuda de agente y registrar esa ayuda. Conservar por separado respuesta original y corregida. Relacionar cada ejercicio con un criterio preparado del paquete; todavía no hay decisiones del aprendiz. Registrar un pasaje leído y su revisión y separar lo que demuestra del siguiente paso propuesto. Informar entradas ausentes como no resueltas. Una respuesta matemática correcta respalda este ejemplo; revisión humana, ejecución real y aceptación del aprendiz necesitan sus propias observaciones conservadas.
