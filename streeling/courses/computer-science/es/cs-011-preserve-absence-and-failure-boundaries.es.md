---
module_id: cs-011-preserve-absence-and-failure-boundaries
department: computer-science
course: "Preservar la distinción entre ausencia y fallo"
level: intermediate
prerequisites: ["cs-010-compose-fail-fast-ga-computations"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Preservar la distinción entre ausencia y fallo

> **Alcance del borrador.** Experimento basado en el código fuente del proyecto, con entradas sintéticas. Siguen pendientes la revisión humana del contenido, la revisión por una persona con dominio del idioma y la revisión por un estudiante; no se afirma que se haya publicado el curso ni verificado su contenido mediante una lectura pública.

## Objetivos y pregunta para el proyecto

Distinguir un valor ausente, un valor presente pero no válido y una excepción de infraestructura; elegir una conversión que conserve la información necesaria para reparar un flujo de trabajo de GA. **Pregunta para el proyecto:** ¿cómo debe una cadena de procesamiento comunicar «no se ha proporcionado ningún artefacto» sin confundirlo con «se ha proporcionado un artefacto, pero no ha superado la validación» o «la operación de almacenamiento ha lanzado una excepción»?

Usa el [módulo GaAsync](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Closures/GaAsync.fs) de GA en la revisión fijada. Define casos de `GaError`, entre ellos `DomainError`, `IoError`, `AgentError` y `PartialFailure`, y proporciona `ofOption` y `fromAsync`. Sus valores usan los tipos estándar [option de F#](https://learn.microsoft.com/dotnet/fsharp/language-reference/options) y [result de F#](https://learn.microsoft.com/dotnet/fsharp/language-reference/results). Esto no es una ejecución de las implementaciones independientes de `Option` o `Try` de GA en C#.

## 1. La presencia no es validez

Una opción indica si un valor está presente: `Some value` o `None`. `Some 0` está presente aunque una regla de dominio posterior rechace el cero. En este escenario de prueba, `ofOption (DomainError "missing-note") (Some 0)` produce `Ok 0`; al pasarlo por una función de validación que exige un entero positivo, se obtiene `Error (DomainError "nonpositive-note")`. Los nombres de los errores indican acciones correctivas distintas: proporcionar la entrada ausente o corregir la entrada suministrada.

La regla numérica es una elección didáctica, no una regla de teoría musical. El cero puede tener significado en una representación de clases de altura. Antes de adoptar un validador en GA, identifica la representación real del dominio y el intervalo aceptado. Este escenario usa enteros deliberadamente para que la conversión pueda examinarse con independencia de un analizador musical.

### Ejercicio práctico 1

Para la regla del escenario suministrado, «el entero debe ser positivo», clasifica `None`, `Some 0` y `Some 5` después de convertir la opción y validar. ¿Por qué clasificar cada cero como «ausente» haría perder información?

> **Respuesta:** `None` se convierte en `DomainError "missing-note"`; `Some 0` se convierte en `DomainError "nonpositive-note"` después de la validación; `Some 5` tiene éxito con 5. Llamar ausente al cero confunde un valor suministrado con la falta de valor y puede llevar al operador a aplicar la corrección equivocada. También traslada la regla del escenario a representaciones donde el cero puede ser válido.

## 2. Especificar el error al convertir una ausencia

El `ofOption` de la revisión fijada acepta un argumento de error y una opción. Transforma `Some x` en `Ok x` y usa el error suministrado para `None`. La propia opción no contenía ningún motivo. Por tanto, la conversión introduce un contexto elegido por quien la llama; no puede recuperar un fallo original cuya información ya se haya descartado.

En un límite propuesto de búsqueda de artefactos, un artefacto ausente podría convertirse en `DomainError "missing-artifact"`. Es un ejemplo didáctico, no evidencia de que este módulo lea un sistema de archivos o una bandeja de entrada de un agente. Una búsqueda que pueda fallar por acceso denegado o pérdida de transporte necesita un resultado más rico antes de la conversión de la opción; de lo contrario, corre el riesgo de ocultar el motivo del fallo.

### Ejercicio práctico 2

Dos búsquedas devuelven `None`: una significa que no hay ningún artefacto configurado y la otra se ha obtenido descartando un error de transporte. ¿Puede `ofOption` inferir cuál ocurrió? ¿Qué debería conservar el límite?

> **Respuesta:** No. Solo ve `None` y el error suministrado por quien lo llama. Conserva un resultado u otro estado explícito que distinga la ausencia del fallo de transporte antes de descartar ese detalle. Llamar «ausente» a cada `None` ocultaría el problema de transporte.

## 3. Medir una proyección con pérdida de información

El ejecutor convierte `Error "missing-note"` y `Error "invalid-pitch"` en opciones estándar de F# con `Result.toOption`. La observación registrada es `[None; None]`. Las dos causas distintas tienen ahora la misma representación. Es una correspondencia concreta de varios valores a uno: un consumidor posterior no puede reconstruir qué mensaje existía a partir de `None` solamente.

Una proyección así puede ser adecuada cuando el consumidor realmente solo necesita conocer la presencia. No sirve para una cola de reparación cuya siguiente acción depende de la causa. Conservar cada diagnóstico indefinidamente también tiene un coste; retén la información exigida por el contrato del consumidor en lugar de tratar el registro máximo como una regla universal.

### Ejercicio práctico 3

Un worker de reintentos solo ve el `None` proyectado de cualquiera de los errores. ¿Puede decidir con seguridad que debe reintentar el transporte de red? Propón una interfaz correcta más sencilla para esa decisión.

> **Respuesta:** No puede inferir de esa opción un fallo de transporte ni la posibilidad de reintento. Conserva la categoría de error original y la evidencia pertinente en un resultado; después, permite que una política explícita de reintentos los examine. Una política anterior también podría proporcionar una decisión booleana de reintento, siempre que su alcance y su evidencia sigan disponibles para auditoría.

## 4. Convertir una excepción en un límite identificado

El `fromAsync` de GA espera un cálculo asíncrono dentro de un bloque `try` y convierte una excepción capturada en `GaError.IoError`, conservando su mensaje y `Some ex`. El laboratorio lanza deliberadamente `System.IO.IOException` con el mensaje `"fixture-io"` dentro de ese límite. El error observado conserva tanto el mensaje como el tipo de excepción. No se provoca ningún fallo de disco; es un escenario de excepción intencionado.

El nombre del caso no demuestra que la causa fuera de E/S. Una excepción distinta capturada por esta envoltura general también recibe el caso `IoError`. Quien la llama debe elegir el límite con rigor e inspeccionar la causa conservada. Este experimento no afirma ninguna garantía de seguridad de cancelación: la entrega de la cancelación y el manejo de excepciones necesitan su propio contrato y sus propias pruebas.

### Ejercicio práctico 4

Si `fromAsync` envuelve una excepción de programación procedente de un cálculo, ¿demuestra el `IoError` resultante que el almacenamiento está averiado? ¿Qué parte del valor devuelto podría ayudar a distinguir la causa?

> **Respuesta:** No. La envoltura asigna ese caso a las excepciones capturadas con independencia del origen real de la operación. La excepción conservada y el mensaje pueden ayudar a investigar la causa. Evita diagnosticar un problema de almacenamiento basándote únicamente en el nombre del caso de la unión.

### Ejercicio práctico 5

Un agente propone convertir cada fallo en `None` antes de entregar el trabajo a un agente de reparación, afirmando que un mensaje más pequeño siempre es mejor. Indica un criterio de refutación y una comparación mínima usando este escenario.

> **Respuesta:** Compara las decisiones de reparación para `missing-note` e `invalid-pitch` cuando se conocen ambas causas y repite después de la proyección a `[None; None]`. Si la segunda interfaz no puede seleccionar las dos correcciones necesarias sin otra búsqueda, queda refutada la afirmación de que conserva suficiente información. Mide el tamaño del mensaje y las búsquedas adicionales frente a un resultado que incluya la categoría necesaria; una carga útil más pequeña por sí sola no demuestra que el flujo de trabajo sea mejor.

## Reproducir el experimento del proyecto

Usa el [laboratorio docente compartido](../../../../code/streeling/functional-composition/README.md), que carga una copia sin cambios del módulo de GA en la revisión fijada y conserva su licencia MIT. [F# Interactive](https://learn.microsoft.com/dotnet/fsharp/tools/fsharp-interactive/) ejecuta el laboratorio sin referencias a paquetes NuGet. Desde la raíz del repositorio Learn, el comando se escribe igual en Windows, Linux/WSL y macOS:

```text
dotnet fsi --exec code/streeling/functional-composition/exercise.fsx
```

El autor observó el SDK `10.0.113` en Windows, código de salida 0, ningún aviso del compilador y 24 aserciones superadas. Queda por verificar el funcionamiento en los demás sistemas operativos. El [registro del experimento](../../../../code/streeling/evidence/functional-composition-2026-10-22/README.md) separa la procedencia de las entradas, la ejecución y la revisión. Son entradas sintéticas ejecutadas por el módulo real de la revisión fijada, no tráfico capturado de la aplicación GA. Lee el cuaderno del estudiante antes de abrir el ejecutor, que contiene las respuestas.

## Evidencia y siguiente comprobación

El módulo inmutable de GA y sus pruebas existentes establecen el caso de estudio basado en el código fuente; las observaciones registradas del laboratorio solo acreditan las entradas que ejecutó. No cuentes una revisión estática de IA como aprobación humana. Una persona revisora debería contrastar las afirmaciones con el código fuente de la revisión fijada; después, un estudiante debería intentar resolver el cuaderno separado con ayuda del código fuente antes de consultar las respuestas. La integración, el despliegue y la verificación pública anónima mediante lectura siguen siendo pasos independientes.
