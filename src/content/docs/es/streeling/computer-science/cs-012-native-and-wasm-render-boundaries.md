---
title: Límites de la comparación entre renderizados nativos y WASM
description: Límites de la comparación entre renderizados nativos y WASM — Ciencias de la computación
sidebar:
  label: CS-012 · Límites de la comparación entre renderizados nativos y WASM
  order: 12
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/computer-science/es/cs-012-native-and-wasm-render-boundaries.es.md
---

:::note[Streeling University]
**CS-012** · Límites de la comparación entre renderizados nativos y WASM · intermedio · 45 minutos

Generado por el departamento *Ciencias de la computación* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/computer-science/es/cs-012-native-and-wasm-render-boundaries.es.md) · [Mi diario](../../journal/)

Requisitos previos: [CS-010](../../computer-science/cs-010-compose-fail-fast-ga-computations/)
:::

> **Alcance del borrador.** Experimento con código fuente ejecutado en Windows x64. Siguen pendientes la revisión técnica humana, la revisión lingüística por una persona que domine el idioma, la ejecución por un estudiante y la verificación del HTML público del curso. Es un recurso didáctico; no se afirma ninguna entrega ni publicación de GA en producción.

## La pregunta del proyecto

Una persona que desarrolla GA quiere poder comparar un renderizado de guitarra sin conexión al pasar de código nativo a [WebAssembly en Node.js](https://nodejs.org/en/learn/getting-started/nodejs-with-webassembly). ¿Qué significa «el mismo resultado»: código fuente, muestras flotantes o audio exportado idénticos? Esta lección distingue esos contratos para evitar que una comparación satisfactoria de archivos apruebe implícitamente una afirmación más fuerte.

Lee el [protocolo del laboratorio](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/README.md), el [programa de ejecución](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/run.mjs), el [registro de procedencia](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/source.json) y los [resultados medidos](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/guitar-runtime-2026-10-22/results.json). El [motor Rust de GA](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs), sin modificar, queda fijado mediante una revisión y una huella del archivo. Aprenderás a delimitar el dominio probado, distinguir igualdad de aproximación e identificar el siguiente experimento necesario antes de ampliar una conclusión.

## Fijar el experimento antes de interpretarlo

Ambas compilaciones usan ese código: un adaptador nativo y el [destino de Rust](https://doc.rust-lang.org/rustc/platform-support/wasm32-unknown-unknown.html) `wasm32-unknown-unknown`. Los comandos didácticos usan `rustc -O`; la configuración de publicación de Cargo del proyecto original usa `opt-level="z"` y LTO. Por tanto, la identidad del código fuente no identifica un binario publicado por el proyecto original. Los argumentos del compilador, el destino y la cadena de herramientas deben acompañar las huellas del código en el registro de ejecución.

Cada variante inicializa un motor nuevo con el perfil 0 a 44100 Hz, solicita un mi grave E2 a 82.4069 Hz y velocidad 0.1, y genera 176400 muestras. La base conserva el decaimiento 0.9978. La candidata aplica 0.9976 después de inicializar y antes de la nota. Son tratamientos distintos: compara nativo y WASM dentro de cada tratamiento antes de comparar tratamientos. Un supuesto erróneo sigue siendo erróneo aunque sea reproducible; escribe la relación esperada antes de abrir los resultados.

### Ejercicio práctico 1

Escribe la predicción más acotada que justifica el código compartido. ¿Basta la huella del código fuente para predecir igualdad de flotantes entre destinos?

> **Respuesta:** Permite prever que el experimento compila el mismo texto del motor, según el procedimiento registrado. No demuestra una ejecución idéntica entre destinos ni igualdad de salidas flotantes. Exige una comparación medida para cada tratamiento y conserva los registros del compilador y del entorno de ejecución. Incluso una igualdad observada describiría solo las entradas y compilaciones probadas.

## Ejecutar una comparación acotada

Sigue primero las instrucciones del laboratorio para descargar y atribuir la grabación de referencia. Desde la raíz del repositorio Learn, sustituye ambos parámetros y elige un directorio de salida que todavía no exista:

```text
node code/streeling/guitar-runtime/run.mjs <new-output-directory> <recorded-wav-path>
```

El programa invoca las herramientas instaladas y registra sus argumentos reales. El entorno registrado usa Rust 1.94.0 y Node v24.12.0 en Windows x64. La ejecución en Linux/WSL y macOS sigue pendiente de verificación. Un fallo puede dejar archivos; examínalos y utiliza otro directorio nuevo para repetir. Leer el registro de una ejecución satisfactoria aporta pruebas sobre esa ejecución, sin demostrar que el estudiante la haya reproducido.

### Ejercicio práctico 2

Un colega llama a la salida «versión WASM de producción» porque su código coincide con GA. ¿Qué pruebas faltan para usar esa descripción?

> **Respuesta:** La compilación didáctica tiene sus propios parámetros y huellas de artefactos. Compara el registro de una compilación de publicación real, su binario y la procedencia del despliegue antes de afirmar esa identidad. El resultado actual debe describirse como una comparación didáctica nativa y Node WebAssembly del código GA fijado. No contiene resultados de publicación DLL, DLSS ni rendimiento.

## Separar la partición del cambio de entorno

El renderizado nativo principal usa un solo bloque; Node WASM emplea bloques de 128 muestras. Esa comparación cambia a la vez el entorno y la partición. Para aislar la partición, pruebas nuevas generan un prefijo de 4096 muestras en un bloque y en particiones de 128 muestras dentro de cada entorno. No hay eventos de nota o parámetro entre bloques. Todas las comparaciones de bytes de esas pruebas pasan, y cada prefijo nuevo coincide con el de su renderizado principal correspondiente.

Esto respalda la igualdad entre particiones para esos prefijos y llamadas sin eventos. No establece invariancia para cualquier duración o evento. En particular, introducir una nota entre bloques cambia la secuencia de entrada. Un planificador del navegador también podría entregar eventos en límites diferentes; esta prueba sin conexión no observa la planificación y no permite resolver esa cuestión.

### Ejercicio práctico 3

Diseña un experimento capaz de refutar la extensión de la conclusión a eventos de parámetro, sin cambiar el veredicto actual.

> **Respuesta:** Define antes de ejecutar un calendario de eventos indexado por muestra y renderiza el mismo calendario con particiones distintas dentro de un entorno. Divide un bloque cuando un evento caiga en su interior para aplicarlo en la misma muestra en ambas rutas. Una secuencia de bytes diferente refutaría la afirmación ampliada. Colocar simplemente el evento en el siguiente límite de bloque compararía entradas distintas.

## Comparar la representación prometida

Las salidas principales nativa y WASM en `f32` bruto difieren en 2918 muestras de la base y 2926 de la candidata. La diferencia absoluta máxima es 2.9802322387695312e-8 para cada variante. Las pruebas no establecen la causa. No la atribuyas a una instrucción, una optimización del compilador o una función matemática sin un experimento que aísle esa causa.

Sin embargo, los bytes WAV PCM16 coinciden entre entornos para cada variante tras la cuantificación con `Math.round(sample * 32767)`. El redondeo asigna varios flotantes al mismo entero. Por ello, los bytes exportados pueden ser iguales aunque los flotantes difieran; no demuestran un estado flotante interno idéntico, que tampoco se capturó.

Una comparación de bytes es sencilla y concluyente cuando el contrato promete bytes exactos. Una cota de error permite aproximaciones, pero necesita un dominio, una métrica y una justificación documentados. Elegir después el máximo observado como tolerancia del producto convertiría una medición en una regla de aceptación sin validar.

### Ejercicio práctico 4

Redacta un veredicto para la salida bruta y otro para el audio exportado. ¿Qué justificaría una futura cota de error?

> **Respuesta:** La igualdad de flotantes brutos entre entornos queda refutada para esta ejecución; la igualdad de bytes WAV cuantificados se confirma para cada variante probada. Una futura cota necesita un requisito establecido de forma independiente de esta observación, casos representativos y un criterio de fallo explícito. La aceptabilidad al escuchar y la equivalencia musical requieren pruebas propias; esta comparación de exportaciones no aporta ninguna de ellas.

## Incluir el adaptador en los límites del experimento

El programa crea una vista de memoria nueva después de cada llamada de renderizado para no depender de una vista retenida entre llamadas que pueden cambiar la memoria. El adaptador nativo libera explícitamente la asignación del motor creada por `Box::into_raw` en este código fijado. Esa limpieza específica del código no garantiza una ABI general. Los casos WASM usan instancias nuevas y breves; la vida de las asignaciones con un uso repetido sigue sin probarse.

Los picos del silencio son 0 y se detectan los 3 controles negativos de PCM malformado. Esos controles verifican el banco de pruebas, no la reproducción en un navegador. La ejecución real en Node WebAssembly no prueba AudioWorklet, la ruta al dispositivo, plazos, cancelación ni escucha. La candidata mejora el error de decaimiento respecto a la grabación en 0.11416614959438576 dB, por debajo del umbral preestablecido de 1 dB; la ejecución tiene éxito mientras `candidate_passes_decline_gate` sigue siendo falso.

### Ejercicio práctico 5

Un agente propone sustituir el programa por un DSL de orquestación compartido. Expón una contrapartida y un criterio de rechazo antes de adoptarlo.

> **Respuesta:** Una descripción compartida podría reducir la duplicación al preparar experimentos, pero añadiría trabajo de interpretación y procedencia. Mantén la propuesta como consultiva hasta que preserve los comandos, el calendario de eventos, las pruebas brutas y cuantificadas, y los veredictos separados de ejecución y aceptación. Recházala si reproducir una discrepancia exige reconstruir valores implícitos. Usa primero el programa actual y sus casos acotados; estudia el ciclo de vida de la memoria y el comportamiento del navegador mediante experimentos separados antes de ampliar cualquier afirmación.
