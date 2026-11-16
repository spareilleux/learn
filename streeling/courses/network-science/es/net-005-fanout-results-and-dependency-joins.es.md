---
module_id: net-005-fanout-results-and-dependency-joins
department: network-science
course: "Resultados de ramas paralelas y uniones de dependencias"
level: intermediate
prerequisites: ["net-004-semantic-backpressure-and-evidence-dependencies"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Resultados de ramas paralelas y uniones de dependencias

> **Alcance del borrador.** Experimento basado en el código fuente del proyecto, con entradas sintéticas. Siguen pendientes la revisión por un especialista humano, la revisión lingüística y la evaluación por un alumno; no se acredita ninguna publicación ni comprobación de la versión pública del curso.

## Objetivos y pregunta para el proyecto

Modelar los cálculos de las ramas y su unión como un pequeño grafo de dependencias, distinguir entre conservar trabajo parcial y tener permiso para publicar un resultado agregado, y probar las hipótesis sobre fallos de una ejecución paralela. **Pregunta para el proyecto:** ¿puede un flujo de trabajo de GA o de agentes conservar resultados independientes útiles cuando falla una rama, sin permitir que una acción que depende de todas las entradas se declare exitosa?

La fuente ejecutable es el [módulo GaAsync de GA en la revisión `dc2e74c`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Closures/GaAsync.fs). Sus funciones `zip` y `fanOutAll` componen [flujos de trabajo asíncronos de F#](https://learn.microsoft.com/dotnet/fsharp/language-reference/async-expressions). Las [pruebas existentes de GA](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Tests/Common/GA.Business.DSL.Tests/GaClosureAndCeTests.cs) incluyen un caso de conservación de resultados parciales. El laboratorio compartido ejecuta este módulo con valores sintéticos de las ramas; no inspecciona las sesiones actuales de wmux ni implementa un planificador distribuido.

## 1. Dibujar la unión antes de elegir el combinador

Consideremos unas ramas independientes A, B y C que alimentan una unión J. Si un artefacto posterior exige las tres ramas, J tiene una dependencia Y: dos entradas exitosas no la satisfacen. Otra acción posterior puede requerir solo A, en cuyo caso el fallo de B no tiene por qué bloquearla. Estas dependencias proceden del contrato del consumidor, no del número de ramas en verde.

El laboratorio asigna las salidas 100 y 300 a las ramas exitosas y `DomainError "missing-branch"` a la rama que falla. Estos enteros son identificadores para la demostración, no contenidos de artefactos ni medidas de calidad. La función real `fanOutAll` devuelve un error que contiene un `PartialFailure` con los éxitos `[100; 300]` y un error. Los valores útiles se conservan, pero el resultado agregado no se ha convertido en `Ok`.

### Ejercicio práctico 1

A y C tienen éxito, mientras que B falla. Una exportación requiere A, B y C, pero un diagnóstico solo necesita A. Según esas dependencias, ¿qué acción tiene todas sus entradas? ¿Autoriza `PartialFailure` por sí mismo alguna de esas acciones externas?

> **Respuesta:** El diagnóstico tiene la entrada que necesita, mientras que la dependencia Y de la exportación está incompleta. `PartialFailure` conserva información sobre los resultados de las ramas; no otorga autorización para ninguna acción externa. El consumidor también debe comprobar la identidad de las entradas, la validez de las revisiones y la autorización.

## 2. No deducir la recopilación parcial de la ejecución paralela

La función `zip` de la revisión fijada ejecuta dos flujos de trabajo con `Async.Parallel`. Si ambos devuelven `Ok`, devuelve su par: el entorno de prueba observa `Ok (2, 3)`. Si ambos devuelven errores de dominio, el código fuente elige el error de la entrada izquierda. El entorno observa `Error (DomainError "left")` y registra por separado que se iniciaron los cuerpos de ambas ramas. Por tanto, elegir un solo error no demuestra que se ejecutara una sola rama.

Esta unión difiere de `bind`: este último omite su función dependiente después de un error, mientras que las entradas de zip son aquí flujos de trabajo independientes que se inician juntos. Una unión paralela puede descartar detalles de diagnóstico aunque se haya realizado trabajo en ambos lados. El error que termina primero no es el criterio de selección que usa la expresión de coincidencia de patrones de esta versión de `zip`.

### Ejercicio práctico 2

Dos ramas de zip devuelven errores de dominio llamados `left` y `right`. Un panel solo muestra `left` y concluye que la rama derecha nunca se inició. ¿Qué observación del entorno de prueba contradice esa conclusión y qué afirmación más amplia sobre los tiempos sigue sin probarse?

> **Respuesta:** El conjunto registrado de ramas iniciadas contiene tanto `left` como `right`, mientras que el resultado elige el error izquierdo. Esto contradice la inferencia de que la otra rama no se inició. El experimento no establece el orden de finalización en producción, la latencia, el rendimiento ni una garantía de equidad del planificador.

## 3. Interpretar las colecciones vacías y aquellas en las que todo falla

El laboratorio observa `Ok []` para una ejecución sin ramas y `Ok [100; 300]` cuando todas las ramas tienen éxito. Con dos entradas fallidas, observa un `PartialFailure` con 0 éxitos y 2 errores, manteniendo el orden de entrada de los dos errores de dominio. En esta implementación, el nombre del caso «partial» no exige que al menos una rama haya tenido éxito.

Un cálculo vacío exitoso no demuestra que existiera trabajo obligatorio ni que se haya realizado. Un consumidor que espera tres salidas de ramas debe validar esa cobertura explícitamente. Del mismo modo, conservar dos valores de error no crea identificadores de ramas. El código fuente conserva los valores exitosos como una `obj list`; extraer los valores de este ejemplo homogéneo de enteros es seguro porque el entorno de prueba conoce su tipo, pero las evidencias heterogéneas necesitan un contenedor con tipo explícito y un contrato de identidad antes de usarse en operaciones.

### Ejercicio práctico 3

Una exportación que requiere tres ramas recibe `Ok []`. ¿Puede marcar su cobertura de dependencias como completa? ¿Qué indica un `PartialFailure` con dos errores y qué información omite?

> **Respuesta:** No. Una colección vacía exitosa no acredita las tres entradas esperadas. El resultado con dos errores registra que los dos cálculos proporcionados a esta colección devolvieron errores y no conservaron ningún éxito; no identifica por sí mismo las ramas requeridas, las revisiones de origen, la política de reintentos ni la autorización para publicar.

## 4. Explicitar la hipótesis sobre las excepciones

`fanOutAll` recopila los valores `Result` devueltos, pero no rodea cada rama con una conversión de excepciones en resultados. La excepción deliberada y no envuelta `System.IO.IOException "unwrapped"` del laboratorio se propaga fuera de la ejecución paralela. No se convierte en un `PartialFailure`. En cambio, envolver la excepción deliberada mediante la función `fromAsync` del módulo produce un `PartialFailure` que conserva el valor exitoso 1 y un `IoError` con el mensaje `"wrapped"` y el tipo de excepción original.

Este es el principal contraejemplo de la afirmación demasiado amplia de que «todas las ramas siempre terminan como valores». Convertir fallos de infraestructura conocidos en un límite identificado puede hacer explícito el canal de error, pero este experimento no demuestra la seguridad ante cancelaciones, la conservación duradera ni que se pueda representar cualquier fallo posible. Una excepción que se propaga en un sistema distribuido puede tener consecuencias distintas de las de este entorno de prueba de F# que se ejecuta dentro de un solo proceso.

### Ejercicio práctico 4

Un desarrollador escribe: «`fanOutAll` siempre conserva las salidas exitosas, haga lo que haga otra rama». ¿Respalda esa afirmación el experimento de la excepción no envuelta? Indique el comportamiento más limitado que se observó realmente.

> **Respuesta:** No. La excepción no envuelta se propaga en lugar de producir el valor de resultados parciales. La conservación de éxitos se observa en las ramas proporcionadas que devuelven resultados, incluida la excepción probada tras su conversión mediante `fromAsync`. No es una garantía sobre excepciones arbitrarias, cancelaciones, pérdida del proceso ni almacenamiento duradero.

## 5. Comparar con un flujo de trabajo más sencillo

Un posible DSL para agentes podría exponer por separado la composición dependiente, las uniones que requieren todas las entradas y la recopilación de resultados parciales. El contraargumento más sólido es que una función explícita breve, junto con una lista de comprobaciones para el consumidor, ya podría expresar el flujo de trabajo. Un DSL nuevo añade costes de análisis sintáctico, depuración, identidad, recuperación y mantenimiento de políticas. Consérvelo como candidato hasta que una comparación medida demuestre una ventaja.

Para un ensayo acotado, use las mismas entradas sintéticas de éxito, error de dominio y excepción en ambas interfaces. Compare las admisiones incorrectas de acciones que exigen todas las entradas, las categorías de error perdidas, los valores útiles de las ramas conservados y el tiempo que necesita un operador para explicar el resultado. Rechace el DSL candidato si admite la exportación incompleta, oculta la distinción de la excepción que se propaga o produce las mismas decisiones con más mantenimiento y sin ninguna ventaja medida. Este curso no implementa ningún DSL.

### Ejercicio práctico 5

Proponga un resultado esperado para una rama con un error de dominio y otro para una excepción no envuelta. Nombre una condición de protección para evaluar un DSL nuevo frente a la composición explícita de funciones GA.

> **Respuesta:** Con las entradas `ok 100`, el error de dominio devuelto y `ok 300`, se espera un resultado agregado fallido que conserve `[100; 300]` y el error. Con la excepción deliberada no envuelta, se espera que la excepción se propague en lugar de producir un `PartialFailure`. Una condición de protección adecuada es no admitir ninguna exportación mientras falte una entrada declarada obligatoria. Registre por separado los diagnósticos perdidos y el tiempo de explicación del operador; superar el entorno de prueba no acredita el rendimiento de un flujo de agentes ni una publicación.

## Reproducir el experimento del proyecto

Use el [laboratorio didáctico compartido](../../../../code/streeling/functional-composition/README.md), que carga una copia sin cambios del módulo de GA en la revisión fijada y conserva su licencia MIT. [F# Interactive](https://learn.microsoft.com/dotnet/fsharp/tools/fsharp-interactive/) ejecuta el laboratorio sin referencias a paquetes NuGet. Desde la raíz del repositorio Learn, la misma escritura del comando se aplica a Windows, Linux/WSL y macOS:

```text
dotnet fsi --exec code/streeling/functional-composition/exercise.fsx
```

El autor observó el SDK `10.0.113` en Windows, código de salida 0, ningún aviso del compilador y 24 aserciones superadas. Los demás sistemas operativos siguen pendientes de verificar. El [registro del experimento](../../../../code/streeling/evidence/functional-composition-2026-10-22/README.md) distingue la procedencia de las entradas, la ejecución y la revisión. Son entradas sintéticas ejecutadas por el módulo real en la revisión fijada, no tráfico capturado de la aplicación GA. Lea el material del alumno antes de abrir el programa de ejecución, que contiene las respuestas.

## Evidencias y próxima comprobación

El módulo inmutable de GA y sus pruebas existentes fundamentan el caso de estudio del código fuente; las observaciones registradas del laboratorio solo acreditan las entradas ejecutadas. No considere una revisión estática realizada por IA como una aprobación humana. Un revisor debería contrastar las afirmaciones con el código fuente de la revisión fijada; después, un alumno debería intentar resolver el material separado que permite consultar el código fuente antes de mirar las respuestas. La integración, el despliegue y la comprobación pública sin autenticación siguen siendo pasos distintos.
